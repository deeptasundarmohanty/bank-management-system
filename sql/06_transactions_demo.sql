USE banking_db;


START TRANSACTION;

UPDATE Account
SET balance = balance - 1000
WHERE account_no = 10001;

SAVEPOINT s1;

UPDATE Account
SET balance = balance + 1000
WHERE account_no = 10002;

ROLLBACK TO SAVEPOINT s1;

COMMIT;


SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;

SELECT *
FROM Account
WHERE account_no = 10001;

COMMIT;


SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

START TRANSACTION;

SELECT *
FROM Account
WHERE account_no = 10001;

COMMIT;


DROP PROCEDURE IF EXISTS transfer;

DELIMITER //

CREATE PROCEDURE transfer(
    IN from_account INT,
    IN to_account INT,
    IN transfer_amount DECIMAL(15,2)
)
BEGIN
    DECLARE sender_balance DECIMAL(15,2);

    START TRANSACTION;

    SELECT balance
    INTO sender_balance
    FROM Account
    WHERE account_no = from_account
    FOR UPDATE;

    IF sender_balance IS NULL THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Sender account not found';

    ELSEIF sender_balance < transfer_amount THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient balance';

    ELSE

        UPDATE Account
        SET balance = balance - transfer_amount
        WHERE account_no = from_account;

        UPDATE Account
        SET balance = balance + transfer_amount
        WHERE account_no = to_account;

        COMMIT;

    END IF;

END //

DELIMITER ;



CALL transfer(10003, 10004, 5000);


CALL transfer(10004, 10003, 99999999);
