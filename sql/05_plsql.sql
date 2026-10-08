
USE bank_db;
DELIMITER $$


CREATE PROCEDURE deposit(IN p_acc INT, IN p_amt DECIMAL(15,2))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  INSERT INTO Bank_Transaction(account_no, txn_type, amount, description)
  VALUES (p_acc, 'DEPOSIT', p_amt, 'Deposit');
  COMMIT;
END$$

CREATE PROCEDURE withdraw(IN p_acc INT, IN p_amt DECIMAL(15,2))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  INSERT INTO Bank_Transaction(account_no, txn_type, amount, description)
  VALUES (p_acc, 'WITHDRAWAL', p_amt, 'Withdrawal');
  COMMIT;
END$$


CREATE PROCEDURE transfer(IN p_from INT, IN p_to INT, IN p_amt DECIMAL(15,2))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK TO SAVEPOINT before_transfer;
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SAVEPOINT before_transfer;
  IF p_from = p_to THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot transfer to the same account';
  END IF;
  INSERT INTO Bank_Transaction(account_no, txn_type, amount, description)
    VALUES (p_from, 'WITHDRAWAL', p_amt, CONCAT('Transfer to ', p_to));
  INSERT INTO Bank_Transaction(account_no, txn_type, amount, description)
    VALUES (p_to, 'DEPOSIT', p_amt, CONCAT('Transfer from ', p_from));
  COMMIT;
END$$

CREATE PROCEDURE get_customer_details(IN p_id INT, OUT p_name VARCHAR(60), OUT p_total DECIMAL(15,2))
BEGIN
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET p_name = NULL;
  SELECT name INTO p_name FROM Customer WHERE customer_id = p_id;
  SELECT IFNULL(SUM(balance),0) INTO p_total FROM Account WHERE customer_id = p_id;
END$$


CREATE FUNCTION get_branch_location(p_acc INT) RETURNS VARCHAR(100)
READS SQL DATA
BEGIN
  DECLARE v_loc VARCHAR(100) DEFAULT 'UNKNOWN';
  SELECT CONCAT(b.branch_name, ', ', b.city) INTO v_loc
  FROM Account a JOIN Branch b ON a.branch_id = b.branch_id
  WHERE a.account_no = p_acc;
  RETURN v_loc;
END$$


CREATE FUNCTION loan_outstanding(p_loan INT) RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
  DECLARE v_amt DECIMAL(15,2) DEFAULT NULL;
  DECLARE v_paid DECIMAL(15,2);
  SELECT amount INTO v_amt FROM Loan WHERE loan_id = p_loan;
  SELECT IFNULL(SUM(amount),0) INTO v_paid FROM Loan_Payment WHERE loan_id = p_loan;
  RETURN v_amt - v_paid;
END$$


CREATE PROCEDURE pay_loan(IN p_loan INT, IN p_amt DECIMAL(15,2))
BEGIN
  DECLARE v_out DECIMAL(15,2);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  SET v_out = loan_outstanding(p_loan);
  IF v_out IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Loan not found';
  END IF;
  IF p_amt > v_out THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment exceeds outstanding loan amount';
  END IF;
  INSERT INTO Loan_Payment(loan_id, amount) VALUES (p_loan, p_amt);
  IF v_out - p_amt = 0 THEN
    UPDATE Loan SET status = 'CLOSED' WHERE loan_id = p_loan;
  END IF;
  COMMIT;
END$$


CREATE PROCEDURE account_exists(IN p_acc INT)
BEGIN
  UPDATE Account SET status = status WHERE account_no = p_acc;   
  IF ROW_COUNT() >= 0 AND EXISTS (SELECT 1 FROM Account WHERE account_no = p_acc) THEN
    SELECT CONCAT('Account ', p_acc, ' exists') AS result;
  ELSE
    SELECT 'No such account' AS result;
  END IF;
END$$


CREATE PROCEDURE mini_statement(IN p_acc INT)
BEGIN
  DECLARE v_id INT;
  DECLARE v_type VARCHAR(12);
  DECLARE v_amt DECIMAL(15,2);
  DECLARE v_date DATETIME;
  DECLARE done INT DEFAULT 0;
  DECLARE c_txn CURSOR FOR
    SELECT txn_id, txn_type, amount, txn_date FROM Bank_Transaction
    WHERE account_no = p_acc ORDER BY txn_date DESC, txn_id DESC LIMIT 10;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  DROP TEMPORARY TABLE IF EXISTS tmp_stmt;
  CREATE TEMPORARY TABLE tmp_stmt (txn_id INT, txn_type VARCHAR(12), amount DECIMAL(15,2), txn_date DATETIME);

  OPEN c_txn;
  read_loop: LOOP
    FETCH c_txn INTO v_id, v_type, v_amt, v_date;
    IF done = 1 THEN LEAVE read_loop; END IF;
    INSERT INTO tmp_stmt VALUES (v_id, v_type, v_amt, v_date);
  END LOOP;
  CLOSE c_txn;
  SELECT * FROM tmp_stmt;
END$$


CREATE PROCEDURE credit_monthly_interest()
BEGIN
  DECLARE v_acc INT;
  DECLARE v_bal DECIMAL(15,2);
  DECLARE done INT DEFAULT 0;
  DECLARE c CURSOR FOR SELECT account_no, balance FROM Account
                       WHERE acc_type = 'SAVINGS' AND status = 'ACTIVE';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;
  OPEN c;
  loop1: LOOP
    FETCH c INTO v_acc, v_bal;
    IF done = 1 THEN LEAVE loop1; END IF;
    IF v_bal > 0 THEN
      INSERT INTO Bank_Transaction(account_no, txn_type, amount, description)
      VALUES (v_acc, 'DEPOSIT', ROUND(v_bal * 0.04 / 12, 2), 'Monthly interest');
    END IF;
  END LOOP;
  CLOSE c;
  COMMIT;
END$$


CREATE PROCEDURE batch_commit_demo()
BEGIN
  DECLARE v_id INT;
  DECLARE n INT DEFAULT 0;
  DECLARE done INT DEFAULT 0;
  DECLARE c CURSOR FOR SELECT txn_id FROM Bank_Transaction ORDER BY txn_id;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  DROP TEMPORARY TABLE IF EXISTS tmp_log;
  CREATE TEMPORARY TABLE tmp_log (txn_id INT);
  START TRANSACTION;
  OPEN c;
  l: LOOP
    FETCH c INTO v_id;
    IF done = 1 THEN LEAVE l; END IF;
    INSERT INTO tmp_log VALUES (v_id);
    SET n = n + 1;
    IF MOD(n, 10) = 0 THEN
      COMMIT;               
      START TRANSACTION;    
    END IF;
  END LOOP;
  CLOSE c;
  COMMIT;
  SELECT * FROM tmp_log;
END$$


CREATE PROCEDURE check_loan_fixed_conflict()
BEGIN
  DECLARE v_cnt INT;
  DECLARE EXIT HANDLER FOR SQLSTATE '45001'
    SELECT CONCAT('Conflict found: ', v_cnt, ' customer(s) have a loan and fixed deposit in the same branch') AS message;
  SELECT COUNT(*) INTO v_cnt
  FROM Loan l JOIN Account a ON a.customer_id = l.customer_id AND a.branch_id = l.branch_id
  WHERE a.acc_type = 'FIXED';
  IF v_cnt > 0 THEN
    SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Business rule violated';
  END IF;
  SELECT 'No conflict' AS message;
END$$

DELIMITER ;

