-- ============================================================
-- Triggers | Unit 3/4 | Lab Exp 5, 10
-- Run after 01_schema.sql, BEFORE 03_sample_data.sql
-- ============================================================

-- T1: Applies every transaction to the account balance, rejects overdraft
CREATE OR REPLACE TRIGGER trg_apply_txn
BEFORE INSERT ON Bank_Transaction
FOR EACH ROW
DECLARE
  v_bal  Account.balance%TYPE;
  v_stat Account.status%TYPE;
BEGIN
  SELECT balance, status INTO v_bal, v_stat
  FROM Account WHERE account_no = :NEW.account_no FOR UPDATE;

  IF v_stat <> 'ACTIVE' THEN
    RAISE_APPLICATION_ERROR(-20002, 'Account is not active');
  END IF;

  IF :NEW.txn_type = 'WITHDRAWAL' THEN
    IF v_bal < :NEW.amount THEN
      RAISE_APPLICATION_ERROR(-20001, 'Insufficient balance');
    END IF;
    UPDATE Account SET balance = balance - :NEW.amount WHERE account_no = :NEW.account_no;
  ELSE
    UPDATE Account SET balance = balance + :NEW.amount WHERE account_no = :NEW.account_no;
  END IF;

  IF :NEW.txn_id IS NULL THEN :NEW.txn_id := seq_txn.NEXTVAL; END IF;
  IF :NEW.txn_date IS NULL THEN :NEW.txn_date := SYSDATE; END IF;
END;
/

-- T2: Transparent audit of UPDATE / DELETE on Account (Exp 5)
CREATE OR REPLACE TRIGGER trg_audit_account
AFTER UPDATE OR DELETE ON Account
FOR EACH ROW
DECLARE v_op VARCHAR2(10);
BEGIN
  v_op := CASE WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END;
  INSERT INTO Account_Audit
  VALUES (seq_audit.NEXTVAL, :OLD.account_no, :OLD.balance,
          CASE WHEN UPDATING THEN :NEW.balance END, v_op, USER, SYSDATE);
END;
/

-- T3: Branch assets maintained when accounts change (keeps derived data consistent)
CREATE OR REPLACE TRIGGER trg_branch_assets
AFTER UPDATE OF balance ON Account
FOR EACH ROW
BEGIN
  UPDATE Branch SET assets = assets + (:NEW.balance - :OLD.balance)
  WHERE branch_id = :NEW.branch_id;
END;
/

-- T4: User-defined error, blocks salary cuts below minimum (Exp 10 style)
CREATE OR REPLACE TRIGGER trg_employee_salary
BEFORE INSERT OR UPDATE ON Employee
FOR EACH ROW
BEGIN
  IF :NEW.salary < 10000 THEN
    RAISE_APPLICATION_ERROR(-20010, 'Salary below minimum wage - operation blocked');
  END IF;
END;
/

-- T5: Prevent closing an account with non-zero balance
CREATE OR REPLACE TRIGGER trg_close_account
BEFORE UPDATE OF status ON Account
FOR EACH ROW
WHEN (NEW.status = 'CLOSED' AND OLD.balance > 0)
BEGIN
  RAISE_APPLICATION_ERROR(-20011, 'Withdraw the balance before closing the account');
END;
/
