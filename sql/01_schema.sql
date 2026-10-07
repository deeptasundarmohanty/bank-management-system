CREATE DATABASE IF NOT EXISTS banking_db;

USE banking_db;


DROP TABLE IF EXISTS Loan_Payment;
DROP TABLE IF EXISTS Loan;
DROP TABLE IF EXISTS Bank_Transaction;
DROP TABLE IF EXISTS Account_Audit;
DROP TABLE IF EXISTS Account;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Branch;

CREATE TABLE Branch (
    branch_id INT PRIMARY KEY AUTO_INCREMENT,
    branch_name VARCHAR(50) NOT NULL UNIQUE,
    city VARCHAR(40) NOT NULL,
    assets DECIMAL(15,2) DEFAULT 0,
    CHECK (assets >= 0)
);


CREATE TABLE Customer (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(60) NOT NULL,
    dob DATE,
    phone VARCHAR(15) UNIQUE,
    email VARCHAR(80) UNIQUE,
    address VARCHAR(120)
);


CREATE TABLE Employee (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(60) NOT NULL,
    `position` VARCHAR(30) NOT NULL,
    salary DECIMAL(10,2),
    branch_id INT NOT NULL,
    manager_id INT,

    CHECK (salary > 0),

    FOREIGN KEY (branch_id)
        REFERENCES Branch(branch_id),

    FOREIGN KEY (manager_id)
        REFERENCES Employee(emp_id)
);



CREATE TABLE Account (
    account_no INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,

    acc_type VARCHAR(10) NOT NULL,

    balance DECIMAL(15,2) DEFAULT 0,

    open_date DATE DEFAULT (CURRENT_DATE),

    status VARCHAR(10) DEFAULT 'ACTIVE',

    CHECK (acc_type IN ('SAVINGS', 'CURRENT', 'FIXED')),

    CHECK (balance >= 0),

    CHECK (status IN ('ACTIVE', 'CLOSED', 'FROZEN')),

    FOREIGN KEY (customer_id)
        REFERENCES Customer(customer_id),

    FOREIGN KEY (branch_id)
        REFERENCES Branch(branch_id)
);


CREATE TABLE Bank_Transaction (
    txn_id INT PRIMARY KEY AUTO_INCREMENT,

    account_no INT NOT NULL,

    txn_type VARCHAR(12) NOT NULL,

    amount DECIMAL(15,2) NOT NULL,

    txn_date DATE DEFAULT (CURRENT_DATE),

    description VARCHAR(100),

    CHECK (txn_type IN ('DEPOSIT', 'WITHDRAWAL')),

    CHECK (amount > 0),

    FOREIGN KEY (account_no)
        REFERENCES Account(account_no)
);


CREATE TABLE Loan (
    loan_id INT PRIMARY KEY AUTO_INCREMENT,

    customer_id INT NOT NULL,

    branch_id INT NOT NULL,

    amount DECIMAL(15,2) NOT NULL,

    interest_rate DECIMAL(5,2) NOT NULL,

    start_date DATE DEFAULT (CURRENT_DATE),

    status VARCHAR(10) DEFAULT 'OPEN',

    CHECK (amount > 0),

    CHECK (status IN ('OPEN', 'CLOSED')),

    FOREIGN KEY (customer_id)
        REFERENCES Customer(customer_id),

    FOREIGN KEY (branch_id)
        REFERENCES Branch(branch_id)
);


CREATE TABLE Loan_Payment (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,

    loan_id INT NOT NULL,

    amount DECIMAL(15,2) NOT NULL,

    pay_date DATE DEFAULT (CURRENT_DATE),

    CHECK (amount > 0),

    FOREIGN KEY (loan_id)
        REFERENCES Loan(loan_id)
        ON DELETE CASCADE
);



CREATE TABLE Account_Audit (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,

    account_no INT,

    old_balance DECIMAL(15,2),

    new_balance DECIMAL(15,2),

    operation VARCHAR(10),

    userid VARCHAR(30),

    op_date DATE DEFAULT (CURRENT_DATE)
);


CREATE INDEX idx_account_cust
ON Account(customer_id);

CREATE INDEX idx_txn_account
ON Bank_Transaction(account_no, txn_date);

CREATE INDEX idx_loan_cust
ON Loan(customer_id);

CREATE INDEX idx_emp_branch
ON Employee(branch_id);



CREATE OR REPLACE VIEW txns AS
SELECT *
FROM Bank_Transaction;


CREATE OR REPLACE VIEW v_customer_accounts AS
SELECT
    c.customer_id,
    c.name,
    a.account_no,
    a.acc_type,
    a.balance,
    b.branch_name
FROM Customer c
JOIN Account a
    ON c.customer_id = a.customer_id
JOIN Branch b
    ON a.branch_id = b.branch_id;


CREATE OR REPLACE VIEW v_loan_outstanding AS
SELECT
    l.loan_id,
    c.name,
    l.amount,
    COALESCE(SUM(p.amount), 0) AS paid,
    l.amount - COALESCE(SUM(p.amount), 0) AS outstanding
FROM Loan l
JOIN Customer c
    ON c.customer_id = l.customer_id
LEFT JOIN Loan_Payment p
    ON p.loan_id = l.loan_id
GROUP BY
    l.loan_id,
    c.name,
    l.amount;



SHOW TABLES;
