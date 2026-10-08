USE bank_db;
DELIMITER $$

CREATE TRIGGER trg_apply_txn
BEFORE INSERT ON Bank_Transaction
FOR EACH ROW
BEGIN
  DECLARE v_bal  DECIMAL(15,2);
  DECLARE v_stat VARCHAR(10);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_bal = NULL;

  SELECT balance, status INTO v_bal, v_stat
  FROM Account WHERE account_no = NEW.account_no FOR UPDATE;

  IF v_bal IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account not found';
  END IF;
  IF v_stat <> 'ACTIVE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account is not active';
  END IF;

  IF NEW.txn_type = 'WITHDRAWAL' THEN
    IF v_bal < NEW.amount THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;
    UPDATE Account SET balance = balance - NEW.amount WHERE account_no = NEW.account_no;
  ELSE
    UPDATE Account SET balance = balance + NEW.amount WHERE account_no = NEW.account_no;
  END IF;
END$$

-- T2: transparent audit of UPDATE and DELETE on Account (Exp 5)
CREATE TRIGGER trg_audit_account_upd
AFTER UPDATE ON Account
FOR EACH ROW
BEGIN
  INSERT INTO Account_Audit(account_no, old_balance, new_balance, operation, userid, op_date)
  VALUES (OLD.account_no, OLD.balance, NEW.balance, 'UPDATE', CURRENT_USER(), NOW());
END$$

CREATE TRIGGER trg_audit_account_del
AFTER DELETE ON Account
FOR EACH ROW
BEGIN
  INSERT INTO Account_Audit(account_no, old_balance, new_balance, operation, userid, op_date)
  VALUES (OLD.account_no, OLD.balance, NULL, 'DELETE', CURRENT_USER(), NOW());
END$$

CREATE TRIGGER trg_branch_assets
AFTER UPDATE ON Account
FOR EACH ROW
BEGIN
  IF NEW.balance <> OLD.balance THEN
    UPDATE Branch SET assets = assets + (NEW.balance - OLD.balance)
    WHERE branch_id = NEW.branch_id;
  END IF;
END$$

CREATE TRIGGER trg_employee_salary_ins
BEFORE INSERT ON Employee
FOR EACH ROW
BEGIN
  IF NEW.salary < 10000 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary below minimum wage - operation blocked';
  END IF;
END$$

CREATE TRIGGER trg_employee_salary_upd
BEFORE UPDATE ON Employee
FOR EACH ROW
BEGIN
  IF NEW.salary < 10000 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary below minimum wage - operation blocked';
  END IF;
END$$


CREATE TRIGGER trg_close_account
BEFORE UPDATE ON Account
FOR EACH ROW
BEGIN
  IF NEW.status = 'CLOSED' AND OLD.status <> 'CLOSED' AND OLD.balance > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Withdraw the balance before closing the account';
  END IF;
END$$

DELIMITER ;
