USE banking_db;


DROP TRIGGER IF EXISTS trg_apply_txn;

DELIMITER //

CREATE TRIGGER trg_apply_txn
BEFORE INSERT ON Bank_Transaction
FOR EACH ROW
BEGIN
    DECLARE v_bal DECIMAL(15,2);
    DECLARE v_stat VARCHAR(10);

    SELECT balance, status
    INTO v_bal, v_stat
    FROM Account
    WHERE account_no = NEW.account_no;

    -- Check account status
    IF v_stat <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account is not active';
    END IF;

    -- Withdrawal
    IF NEW.txn_type = 'WITHDRAWAL' THEN

        IF v_bal < NEW.amount THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient balance';
        END IF;

        UPDATE Account
        SET balance = balance - NEW.amount
        WHERE account_no = NEW.account_no;

    -- Deposit
    ELSE

        UPDATE Account
        SET balance = balance + NEW.amount
        WHERE account_no = NEW.account_no;

    END IF;

    -- Automatically generate transaction date
    IF NEW.txn_date IS NULL THEN
        SET NEW.txn_date = CURRENT_DATE;
    END IF;

END //

DELIMITER ;

DROP TRIGGER IF EXISTS trg_audit_account;

DELIMITER //

CREATE TRIGGER trg_audit_account
AFTER UPDATE ON Account
FOR EACH ROW
BEGIN

    INSERT INTO Account_Audit
    (
        account_no,
        old_balance,
        new_balance,
        operation,
        userid,
        op_date
    )
    VALUES
    (
        OLD.account_no,
        OLD.balance,
        NEW.balance,
        'UPDATE',
        CURRENT_USER(),
        CURRENT_DATE
    );

END //

DELIMITER ;

DROP TRIGGER IF EXISTS trg_audit_account_delete;

DELIMITER //

CREATE TRIGGER trg_audit_account_delete
AFTER DELETE ON Account
FOR EACH ROW
BEGIN

    INSERT INTO Account_Audit
    (
        account_no,
        old_balance,
        new_balance,
        operation,
        userid,
        op_date
    )
    VALUES
    (
        OLD.account_no,
        OLD.balance,
        NULL,
        'DELETE',
        CURRENT_USER(),
        CURRENT_DATE
    );

END //

DELIMITER ;


DROP TRIGGER IF EXISTS trg_branch_assets;

DELIMITER //

CREATE TRIGGER trg_branch_assets
AFTER UPDATE ON Account
FOR EACH ROW
BEGIN

    UPDATE Branch
    SET assets = assets + (NEW.balance - OLD.balance)
    WHERE branch_id = NEW.branch_id;

END //

DELIMITER ;



DROP TRIGGER IF EXISTS trg_employee_salary;

DELIMITER //

CREATE TRIGGER trg_employee_salary
BEFORE INSERT ON Employee
FOR EACH ROW
BEGIN

    IF NEW.salary < 10000 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Salary below minimum wage - operation blocked';

    END IF;

END //

DELIMITER ;

DROP TRIGGER IF EXISTS trg_employee_salary_update;

DELIMITER //

CREATE TRIGGER trg_employee_salary_update
BEFORE UPDATE ON Employee
FOR EACH ROW
BEGIN

    IF NEW.salary < 10000 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Salary below minimum wage - operation blocked';

    END IF;

END //

DELIMITER ;


DROP TRIGGER IF EXISTS trg_close_account;

DELIMITER //

CREATE TRIGGER trg_close_account
BEFORE UPDATE ON Account
FOR EACH ROW
BEGIN

    IF NEW.status = 'CLOSED'
       AND OLD.balance > 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Withdraw the balance before closing the account';

    END IF;

END //

DELIMITER ;


SHOW TRIGGERS;
