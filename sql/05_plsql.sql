-- ============================================================
-- PL/SQL | Unit 4 | Lab Exp 4, 6, 7, 8, 9
-- SET SERVEROUTPUT ON before running
-- ============================================================
SET SERVEROUTPUT ON

-- P1: Deposit / withdraw (trigger updates the balance)
CREATE OR REPLACE PROCEDURE deposit(p_acc NUMBER, p_amt NUMBER) IS
BEGIN
  INSERT INTO Bank_Transaction(txn_id,account_no,txn_type,amount,description)
  VALUES (seq_txn.NEXTVAL, p_acc, 'DEPOSIT', p_amt, 'Deposit');
  COMMIT;
END;
/
CREATE OR REPLACE PROCEDURE withdraw(p_acc NUMBER, p_amt NUMBER) IS
BEGIN
  INSERT INTO Bank_Transaction(txn_id,account_no,txn_type,amount,description)
  VALUES (seq_txn.NEXTVAL, p_acc, 'WITHDRAWAL', p_amt, 'Withdrawal');
  COMMIT;
END;
/

-- P2: Fund transfer using SAVEPOINT / ROLLBACK (atomic)
CREATE OR REPLACE PROCEDURE transfer(p_from NUMBER, p_to NUMBER, p_amt NUMBER) IS
BEGIN
  IF p_from = p_to THEN RAISE_APPLICATION_ERROR(-20020,'Same account'); END IF;
  SAVEPOINT before_transfer;
  INSERT INTO Bank_Transaction(txn_id,account_no,txn_type,amount,description)
    VALUES (seq_txn.NEXTVAL, p_from, 'WITHDRAWAL', p_amt, 'Transfer to '||p_to);
  INSERT INTO Bank_Transaction(txn_id,account_no,txn_type,amount,description)
    VALUES (seq_txn.NEXTVAL, p_to, 'DEPOSIT', p_amt, 'Transfer from '||p_from);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO before_transfer;
    RAISE;
END;
/

-- P3: Procedure with OUT parameters (Exp 8/9 style)
CREATE OR REPLACE PROCEDURE get_customer_details(p_id IN NUMBER, p_name OUT VARCHAR2, p_total OUT NUMBER) IS
BEGIN
  SELECT c.name, NVL(SUM(a.balance),0) INTO p_name, p_total
  FROM Customer c LEFT JOIN Account a ON a.customer_id = c.customer_id
  WHERE c.customer_id = p_id GROUP BY c.name;
EXCEPTION
  WHEN NO_DATA_FOUND THEN p_name := NULL; p_total := 0;
END;
/

-- F1: Function: branch address/city of an account (Exp 8 style)
CREATE OR REPLACE FUNCTION get_branch_location(p_acc NUMBER) RETURN VARCHAR2 IS
  v_loc VARCHAR2(100);
BEGIN
  SELECT b.branch_name||', '||b.city INTO v_loc
  FROM Account a JOIN Branch b ON a.branch_id = b.branch_id WHERE a.account_no = p_acc;
  RETURN v_loc;
EXCEPTION WHEN NO_DATA_FOUND THEN RETURN 'UNKNOWN';
END;
/
-- Call inside SQL:
-- SELECT a.account_no, get_branch_location(a.account_no) FROM Account a;

-- F2: Loan outstanding
CREATE OR REPLACE FUNCTION loan_outstanding(p_loan NUMBER) RETURN NUMBER IS
  v_amt NUMBER; v_paid NUMBER;
BEGIN
  SELECT amount INTO v_amt FROM Loan WHERE loan_id = p_loan;
  SELECT NVL(SUM(amount),0) INTO v_paid FROM Loan_Payment WHERE loan_id = p_loan;
  RETURN v_amt - v_paid;
END;
/

-- P4: Loan payment with user-defined exception (overpayment)
CREATE OR REPLACE PROCEDURE pay_loan(p_loan NUMBER, p_amt NUMBER) IS
  e_overpay EXCEPTION;
  v_out NUMBER;
BEGIN
  v_out := loan_outstanding(p_loan);
  IF p_amt > v_out THEN RAISE e_overpay; END IF;
  INSERT INTO Loan_Payment(payment_id,loan_id,amount) VALUES (seq_payment.NEXTVAL,p_loan,p_amt);
  IF v_out - p_amt = 0 THEN UPDATE Loan SET status='CLOSED' WHERE loan_id=p_loan; END IF;
  COMMIT;
EXCEPTION
  WHEN e_overpay THEN
    RAISE_APPLICATION_ERROR(-20030,'Payment exceeds outstanding loan of '||v_out);
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20031,'Loan not found');
END;
/

-- C1: Implicit cursor (Exp 4): details of transactions count for an account
DECLARE
  v_acc NUMBER := 10001;
BEGIN
  UPDATE Account SET status = status WHERE account_no = v_acc;
  IF SQL%FOUND THEN DBMS_OUTPUT.PUT_LINE('Account '||v_acc||' exists, rows: '||SQL%ROWCOUNT);
  ELSE DBMS_OUTPUT.PUT_LINE('No such account'); END IF;
  ROLLBACK;
END;
/

-- C2: Explicit cursor - mini statement
CREATE OR REPLACE PROCEDURE mini_statement(p_acc NUMBER) IS
  CURSOR c_txn IS
    SELECT txn_id, txn_type, amount, txn_date FROM Bank_Transaction
    WHERE account_no = p_acc ORDER BY txn_date DESC, txn_id DESC;
  r c_txn%ROWTYPE;
  n NUMBER := 0;
BEGIN
  OPEN c_txn;
  LOOP
    FETCH c_txn INTO r;
    EXIT WHEN c_txn%NOTFOUND OR n = 10;
    DBMS_OUTPUT.PUT_LINE(r.txn_id||' | '||RPAD(r.txn_type,10)||' | '||r.amount||' | '||TO_CHAR(r.txn_date,'DD-MON-YY'));
    n := n + 1;
  END LOOP;
  CLOSE c_txn;
END;
/

-- C3: Cursor FOR loop - monthly interest on savings accounts (4% p.a.)
CREATE OR REPLACE PROCEDURE credit_monthly_interest IS
BEGIN
  FOR r IN (SELECT account_no, balance FROM Account WHERE acc_type='SAVINGS' AND status='ACTIVE') LOOP
    INSERT INTO Bank_Transaction(txn_id,account_no,txn_type,amount,description)
    VALUES (seq_txn.NEXTVAL, r.account_no, 'DEPOSIT', ROUND(r.balance*0.04/12,2), 'Monthly interest');
  END LOOP;
  COMMIT;
END;
/

-- C4: Exp 6 style: cursor with commit after every 10th row and savepoint
DECLARE
  CURSOR c IS SELECT txn_id FROM Bank_Transaction ORDER BY txn_id;
  v_id NUMBER; n NUMBER := 0;
BEGIN
  OPEN c;
  LOOP
    FETCH c INTO v_id; EXIT WHEN c%NOTFOUND;
    n := n + 1;
    DBMS_OUTPUT.PUT_LINE('Txn '||v_id);
    IF MOD(n,10) = 0 THEN SAVEPOINT sp_ten; COMMIT; END IF;
  END LOOP;
  CLOSE c;
END;
/

-- E1: Exp 7 style: customer should not hold both a loan and savings in the same branch?
-- Business rule here: a loan officer cannot approve loan for own account holder -> use exception
DECLARE
  e_conflict EXCEPTION;
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM Loan l JOIN Account a
    ON a.customer_id=l.customer_id AND a.branch_id=l.branch_id
  WHERE a.acc_type='FIXED';
  IF v_cnt > 0 THEN RAISE e_conflict; END IF;
  DBMS_OUTPUT.PUT_LINE('No conflict');
EXCEPTION WHEN e_conflict THEN
  DBMS_OUTPUT.PUT_LINE('Conflict found: loan + fixed deposit in same branch (count '||v_cnt||')');
END;
/

-- Composite data type: record + collection
DECLARE
  TYPE t_cust IS RECORD (id Customer.customer_id%TYPE, nm Customer.name%TYPE);
  TYPE t_tab  IS TABLE OF t_cust INDEX BY PLS_INTEGER;
  v t_tab; i PLS_INTEGER := 0;
BEGIN
  FOR r IN (SELECT customer_id, name FROM Customer) LOOP
    i := i + 1; v(i).id := r.customer_id; v(i).nm := r.name;
  END LOOP;
  FOR j IN 1..v.COUNT LOOP DBMS_OUTPUT.PUT_LINE(v(j).id||' '||v(j).nm); END LOOP;
END;
/
