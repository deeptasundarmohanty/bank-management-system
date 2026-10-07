USE banking_db;

SELECT name, phone
FROM Customer
WHERE address = 'Chennai'
ORDER BY name;

SELECT *
FROM Account
WHERE balance > 50000
ORDER BY balance DESC;

SELECT
    c.name,
    a.account_no,
    a.acc_type,
    b.branch_name
FROM Customer c
JOIN Account a
    ON c.customer_id = a.customer_id
JOIN Branch b
    ON b.branch_id = a.branch_id;


SELECT
    c.name,
    a.account_no
FROM Customer c
LEFT JOIN Account a
    ON c.customer_id = a.customer_id;


SELECT
    e.name,
    b.branch_name
FROM Employee e
JOIN Branch b
    ON e.branch_id = b.branch_id;

SELECT
    e.name AS employee,
    COALESCE(m.name, ' ') AS boss
FROM Employee e
LEFT JOIN Employee m
    ON e.manager_id = m.emp_id;


SELECT
    m.emp_id,
    m.name,
    COUNT(e.emp_id) AS managed
FROM Employee m
JOIN Employee e
    ON e.manager_id = m.emp_id
GROUP BY m.emp_id, m.name
ORDER BY managed DESC;

SELECT
    b.branch_name,
    e.name AS manager
FROM Branch b
LEFT JOIN Employee e
    ON e.branch_id = b.branch_id
    AND e.position = 'Manager';


SELECT
    branch_id,
    COUNT(*) AS accounts,
    SUM(balance) AS total,
    AVG(balance) AS avg_bal
FROM Account
GROUP BY branch_id
HAVING SUM(balance) > 50000;


SELECT
    MAX(balance) AS highest_balance,
    MIN(balance) AS lowest_balance
FROM Account;

SELECT COUNT(DISTINCT name) AS unique_customers
FROM Customer;
