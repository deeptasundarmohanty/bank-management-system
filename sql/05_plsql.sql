USE banking_db;

DROP PROCEDURE IF EXISTS deposit;

DELIMITER //

CREATE PROCEDURE deposit(
    IN p_acc INT,
    IN p_amt DECIMAL(15,2)
)
BEGIN

    INSERT INTO Bank_Transaction
    (
        account_no,
        txn_type,
        amount,
        description
    )
    VALUES
    (
        p_acc,
        'DEPOSIT',
        p_amt,
        'Deposit'
    );

    COMMIT;

END //

DELIMITER ;


DROP PROCEDURE IF EXISTS withdraw;

DELIMITER //

CREATE PROCEDURE withdraw(
    IN p_acc INT,
    IN p_amt DECIMAL(15,2)
)
BEGIN

    INSERT INTO Bank_Transaction
    (
        account_no,
        txn_type,
        amount,
        description
    )
    VALUES
    (
        p_acc,
        'WITHDRAWAL',
        p_amt,
        'Withdrawal'
    );

    COMMIT;

END //

DELIMITER ;


DROP PROCEDURE IF EXISTS transfer;

DELIMITER //

CREATE PROCEDURE transfer(
    IN p_from INT,
    IN p_to INT,
    IN p_amt DECIMAL(15,2)
)
BEGIN

    DECLARE v_balance DECIMAL(15,2);

    START TRANSACTION;

    -- Same account check
    IF p_from = p_to THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Same account';

    END IF;

   
    SELECT balance
    INTO v_balance
    FROM Account
    WHERE account_no = p_from
    FOR UPDATE;

    IF v_balance < p_amt THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient balance';

    END IF;

  
    INSERT INTO Bank_Transaction
    (
        account_no,
        txn_type,
        amount,
        description
    )
    VALUES
    (
        p_from,
        'WITHDRAWAL',
        p_amt,
        CONCAT('Transfer to ', p_to)
    );

    -- Deposit to receiver
    INSERT INTO Bank_Transaction
    (
        account_no,
        txn_type,
        amount,
        description
    )
    VALUES
    (
        p_to,
        'DEPOSIT',
        p_amt,
        CONCAT('Transfer from ', p_from)
    );

    COMMIT;

END //

DELIMITER ;


DROP PROCEDURE IF EXISTS get_customer_details;

DELIMITER //

CREATE PROCEDURE get_customer_details(
    IN p_id INT,
    OUT p_name VARCHAR(60),
    OUT p_total DECIMAL(15,2)
)
BEGIN

    SELECT
        c.name,
        COALESCE(SUM(a.balance), 0)
    INTO
        p_name,
        p_total
    FROM Customer c
    LEFT JOIN Account a
        ON a.customer_id = c.customer_id
    WHERE c.customer_id = p_id
    GROUP BY c.name;

END //

DELIMITER ;



DROP FUNCTION IF EXISTS get_branch_location;

DELIMITER //

CREATE FUNCTION get_branch_location(
    p_acc INT
)
RETURNS VARCHAR(100)
DETERMINISTIC
READS SQL DATA
BEGIN

    DECLARE v_loc VARCHAR(100);

    SELECT CONCAT(b.branch_name, ', ', b.city)
    INTO v_loc
    FROM Account a
    JOIN Branch b
        ON a.branch_id = b.branch_id
    WHERE a.account_no = p_acc;

    IF v_loc IS NULL THEN
        SET v_loc = 'UNKNOWN';
    END IF;

    RETURN v_loc;

END //

DELIMITER ;



DROP FUNCTION IF EXISTS loan_outstanding;

DELIMITER //

CREATE FUNCTION loan_outstanding(
    p_loan INT
)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN

    DECLARE v_amt DECIMAL(15,2);
    DECLARE v_paid DECIMAL(15,2);

    SELECT amount
    INTO v_amt
    FROM Loan
    WHERE loan_id = p_loan;

    SELECT COALESCE(SUM(amount), 0)
    INTO v_paid
    FROM Loan_Payment
    WHERE loan_id = p_loan;

    RETURN v_amt - v_paid;

END //

DELIMITER ;



DROP PROCEDURE IF EXISTS pay_loan;

DELIMITER //

CREATE PROCEDURE pay_loan(
    IN p_loan INT,
    IN p_amt DECIMAL(15,2)
)
BEGIN

    DECLARE v_out DECIMAL(15,2);

    SET v_out = loan_outstanding(p_loan);

    IF p_amt > v_out THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment exceeds outstanding loan';

    END IF;

    INSERT INTO Loan_Payment
    (
        loan_id,
        amount
    )
    VALUES
    (
        p_loan,
        p_amt
    );

    IF v_out - p_amt = 0 THEN

        UPDATE Loan
        SET status = 'CLOSED'
        WHERE loan_id = p_loan;

    END IF;

    COMMIT;

END //

DELIMITER ;



DROP PROCEDURE IF EXISTS check_account;

DELIMITER //

CREATE PROCEDURE check_account(
    IN p_acc INT
)
BEGIN

    IF EXISTS
    (
        SELECT 1
        FROM Account
        WHERE account_no = p_acc
    ) THEN

        SELECT
            CONCAT(
                'Account ',
                p_acc,
                ' exists'
            ) AS message;

    ELSE

        SELECT
            'No such account' AS message;

    END IF;

END //

DELIMITER ;



DROP PROCEDURE IF EXISTS mini_statement;

DELIMITER //

CREATE PROCEDURE mini_statement(
    IN p_acc INT
)
BEGIN

    SELECT
        txn_id,
        txn_type,
        amount,
        txn_date
    FROM Bank_Transaction
    WHERE account_no = p_acc
    ORDER BY txn_date DESC, txn_id DESC
    LIMIT 10;

END //

DELIMITER ;


DROP PROCEDURE IF EXISTS credit_monthly_interest;

DELIMITER //

CREATE PROCEDURE credit_monthly_interest()
BEGIN

    INSERT INTO Bank_Transaction
    (
        account_no,
        txn_type,
        amount,
        description
    )
    SELECT
        account_no,
        'DEPOSIT',
        ROUND(balance * 0.04 / 12, 2),
        'Monthly interest'
    FROM Account
    WHERE acc_type = 'SAVINGS'
      AND status = 'ACTIVE'
      AND balance > 0;

    COMMIT;

END //

DELIMITER ;



SELECT
    customer_id,
    name
FROM Customer
ORDER BY customer_id;


SHOW PROCEDURE STATUS
WHERE Db = 'banking_db';

SHOW FUNCTION STATUS
WHERE Db = 'banking_db';
