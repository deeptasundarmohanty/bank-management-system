-- ============================================================
-- Queries  | Syllabus Unit 3 + Lab Exp 2, 11
-- ============================================================
-- 1. Basic SELECT, restricting, sorting
SELECT name, phone FROM Customer WHERE address = 'Chennai' ORDER BY name;
SELECT * FROM Account WHERE balance > 50000 ORDER BY balance DESC;

-- 2. Joins: customer with account and branch
SELECT c.name, a.account_no, a.acc_type, b.branch_name
FROM Customer c JOIN Account a ON c.customer_id = a.customer_id
                JOIN Branch b  ON b.branch_id   = a.branch_id;

-- 3. Outer join: customers with NO account / all customers with accounts
SELECT c.name, a.account_no FROM Customer c LEFT JOIN Account a ON c.customer_id = a.customer_id;

-- 4. Employee with department(branch) name
SELECT e.name, b.branch_name FROM Employee e JOIN Branch b ON e.branch_id = b.branch_id;

-- 5. Self join: employee with boss (blank for top boss)
SELECT e.name AS employee, NVL(m.name,' ') AS boss
FROM Employee e LEFT JOIN Employee m ON e.manager_id = m.emp_id;

-- 6. Employees who manage others + count, descending
SELECT m.emp_id, m.name, COUNT(e.emp_id) AS managed
FROM Employee m JOIN Employee e ON e.manager_id = m.emp_id
GROUP BY m.emp_id, m.name ORDER BY managed DESC;

-- 7. Branches with their manager
SELECT b.branch_name, e.name AS manager
FROM Branch b LEFT JOIN Employee e ON e.branch_id = b.branch_id AND e.position='Manager';

-- 8. Aggregates / GROUP BY / HAVING
SELECT branch_id, COUNT(*) AS accounts, SUM(balance) AS total, AVG(balance) AS avg_bal
FROM Account GROUP BY branch_id HAVING SUM(balance) > 50000;
SELECT MAX(balance) oldest_rich, MIN(balance) lowest FROM Account;
SELECT COUNT(DISTINCT name) FROM Customer;

-- 9. Nested subqueries
-- customers whose balance is above average
SELECT name FROM Customer WHERE customer_id IN
  (SELECT customer_id FROM Account WHERE balance > (SELECT AVG(balance) FROM Account));
-- account with highest balance using ALL
SELECT account_no FROM Account WHERE balance >= ALL (SELECT balance FROM Account);
-- customers who have never taken a loan (NOT EXISTS)
SELECT name FROM Customer c WHERE NOT EXISTS (SELECT 1 FROM Loan l WHERE l.customer_id = c.customer_id);
-- customers with both account and loan (correlated EXISTS)
SELECT name FROM Customer c WHERE EXISTS (SELECT 1 FROM Loan l WHERE l.customer_id=c.customer_id)
                              AND EXISTS (SELECT 1 FROM Account a WHERE a.customer_id=c.customer_id);

-- 10. Set operators
SELECT customer_id FROM Account INTERSECT SELECT customer_id FROM Loan;
SELECT customer_id FROM Customer MINUS SELECT customer_id FROM Account;
SELECT customer_id FROM Account UNION SELECT customer_id FROM Loan;

-- 11. Division-style query: customers having accounts in EVERY Chennai branch
SELECT c.name FROM Customer c WHERE NOT EXISTS (
  SELECT b.branch_id FROM Branch b WHERE b.city='Chennai' AND NOT EXISTS (
    SELECT 1 FROM Account a WHERE a.customer_id=c.customer_id AND a.branch_id=b.branch_id));

-- 12. Single-row, conversion and conditional functions
SELECT UPPER(name), TO_CHAR(dob,'DD-MON-YYYY'), TRUNC(MONTHS_BETWEEN(SYSDATE,dob)/12) AS age FROM Customer;
SELECT account_no, balance,
  CASE WHEN balance >= 100000 THEN 'GOLD' WHEN balance >= 25000 THEN 'SILVER' ELSE 'BASIC' END AS tier
FROM Account;
SELECT name, NVL(email,'N/A') FROM Customer;

-- 13. Reports from views
SELECT * FROM v_customer_accounts;
SELECT * FROM v_loan_outstanding WHERE outstanding > 0;

-- 14. Monthly transaction summary
SELECT TO_CHAR(txn_date,'YYYY-MM') AS month, txn_type, SUM(amount) total, COUNT(*) cnt
FROM Bank_Transaction GROUP BY TO_CHAR(txn_date,'YYYY-MM'), txn_type ORDER BY 1;

-- 15. Top 3 customers by total balance
SELECT * FROM (SELECT c.name, SUM(a.balance) total FROM Customer c JOIN Account a
  ON a.customer_id=c.customer_id GROUP BY c.name ORDER BY total DESC) WHERE ROWNUM <= 3;

-- 16. Data dictionary
SELECT table_name FROM user_tables;
SELECT constraint_name, constraint_type, table_name FROM user_constraints;

-- 17. Relational algebra equivalents are given in README_Report.md
