
USE bank_db;

SELECT name, phone FROM Customer WHERE address = 'Chennai' ORDER BY name;
SELECT * FROM Account WHERE balance > 50000 ORDER BY balance DESC;

SELECT c.name, a.account_no, a.acc_type, b.branch_name
FROM Customer c JOIN Account a ON c.customer_id = a.customer_id
                JOIN Branch b  ON b.branch_id   = a.branch_id;

SELECT c.name, a.account_no FROM Customer c LEFT JOIN Account a ON c.customer_id = a.customer_id;

SELECT e.name, b.branch_name FROM Employee e JOIN Branch b ON e.branch_id = b.branch_id;

SELECT e.name AS employee, IFNULL(m.name,' ') AS boss
FROM Employee e LEFT JOIN Employee m ON e.manager_id = m.emp_id;

SELECT m.emp_id, m.name, COUNT(e.emp_id) AS managed
FROM Employee m JOIN Employee e ON e.manager_id = m.emp_id
GROUP BY m.emp_id, m.name ORDER BY managed DESC;

SELECT b.branch_name, e.name AS manager
FROM Branch b LEFT JOIN Employee e ON e.branch_id = b.branch_id AND e.position='Manager';

SELECT branch_id, COUNT(*) AS accounts, SUM(balance) AS total, AVG(balance) AS avg_bal
FROM Account GROUP BY branch_id HAVING SUM(balance) > 50000;
SELECT MAX(balance) AS highest, MIN(balance) AS lowest FROM Account;
SELECT COUNT(DISTINCT name) FROM Customer;

SELECT name FROM Customer WHERE customer_id IN
  (SELECT customer_id FROM Account WHERE balance > (SELECT AVG(balance) FROM Account));
SELECT account_no FROM Account WHERE balance >= ALL (SELECT balance FROM Account);
SELECT name FROM Customer c WHERE NOT EXISTS (SELECT 1 FROM Loan l WHERE l.customer_id = c.customer_id);
SELECT name FROM Customer c WHERE EXISTS (SELECT 1 FROM Loan l WHERE l.customer_id=c.customer_id)
                              AND EXISTS (SELECT 1 FROM Account a WHERE a.customer_id=c.customer_id);

SELECT customer_id FROM Account UNION SELECT customer_id FROM Loan;
SELECT customer_id FROM Account INTERSECT SELECT customer_id FROM Loan;
SELECT customer_id FROM Customer EXCEPT SELECT customer_id FROM Account;

SELECT DISTINCT customer_id FROM Account WHERE customer_id IN (SELECT customer_id FROM Loan);
SELECT customer_id FROM Customer WHERE customer_id NOT IN (SELECT customer_id FROM Account);

SELECT c.name FROM Customer c WHERE NOT EXISTS (
  SELECT b.branch_id FROM Branch b WHERE b.city='Chennai' AND NOT EXISTS (
    SELECT 1 FROM Account a WHERE a.customer_id=c.customer_id AND a.branch_id=b.branch_id));

SELECT UPPER(name), DATE_FORMAT(dob,'%d-%b-%Y') AS dob_fmt,
       TIMESTAMPDIFF(YEAR, dob, CURDATE()) AS age FROM Customer;
SELECT account_no, balance,
  CASE WHEN balance >= 100000 THEN 'GOLD' WHEN balance >= 25000 THEN 'SILVER' ELSE 'BASIC' END AS tier
FROM Account;
SELECT name, IFNULL(email,'N/A') FROM Customer;

SELECT * FROM v_customer_accounts;
SELECT * FROM v_loan_outstanding WHERE outstanding > 0;

SELECT DATE_FORMAT(txn_date,'%Y-%m') AS month, txn_type, SUM(amount) AS total, COUNT(*) AS cnt
FROM Bank_Transaction GROUP BY month, txn_type ORDER BY month;

SELECT c.name, SUM(a.balance) AS total
FROM Customer c JOIN Account a ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.name ORDER BY total DESC LIMIT 3;

SELECT table_name FROM information_schema.tables WHERE table_schema = 'bank_db';
SELECT constraint_name, constraint_type, table_name
FROM information_schema.table_constraints WHERE table_schema = 'bank_db';
