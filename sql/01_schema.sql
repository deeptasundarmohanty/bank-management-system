DROP DATABASE IF EXISTS bank_db;
CREATE DATABASE bank_db CHARACTER SET utf8mb4;
USE bank_db;

CREATE TABLE Branch (
  branch_id    INT AUTO_INCREMENT PRIMARY KEY,
  branch_name  VARCHAR(50) NOT NULL UNIQUE,
  city         VARCHAR(40) NOT NULL,
  assets       DECIMAL(15,2) DEFAULT 0 CHECK (assets >= 0)
) ENGINE=InnoDB AUTO_INCREMENT=100;

CREATE TABLE Customer (
  customer_id  INT AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(60) NOT NULL,
  dob          DATE,
  phone        VARCHAR(15) UNIQUE,
  email        VARCHAR(80) UNIQUE,
  address      VARCHAR(120)
) ENGINE=InnoDB AUTO_INCREMENT=1000;

CREATE TABLE Employee (
  emp_id       INT AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(60) NOT NULL,
  position     VARCHAR(30) NOT NULL,
  salary       DECIMAL(10,2) CHECK (salary > 0),
  branch_id    INT NOT NULL,
  manager_id   INT NULL,                              -- self reference (boss)
  FOREIGN KEY (branch_id)  REFERENCES Branch(branch_id),
  FOREIGN KEY (manager_id) REFERENCES Employee(emp_id)
) ENGINE=InnoDB AUTO_INCREMENT=500;

CREATE TABLE Account (
  account_no   INT AUTO_INCREMENT PRIMARY KEY,
  customer_id  INT NOT NULL,
  branch_id    INT NOT NULL,
  acc_type     VARCHAR(10) NOT NULL CHECK (acc_type IN ('SAVINGS','CURRENT','FIXED')),
  balance      DECIMAL(15,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
  open_date    DATE DEFAULT (CURRENT_DATE),
  status       VARCHAR(10) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','CLOSED','FROZEN')),
  FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
  FOREIGN KEY (branch_id)   REFERENCES Branch(branch_id)
) ENGINE=InnoDB AUTO_INCREMENT=10001;

CREATE TABLE Bank_Transaction (
  txn_id       INT AUTO_INCREMENT PRIMARY KEY,
  account_no   INT NOT NULL,
  txn_type     VARCHAR(12) NOT NULL CHECK (txn_type IN ('DEPOSIT','WITHDRAWAL')),
  amount       DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  txn_date     DATETIME DEFAULT CURRENT_TIMESTAMP,
  description  VARCHAR(100),
  FOREIGN KEY (account_no) REFERENCES Account(account_no)
) ENGINE=InnoDB;

CREATE TABLE Loan (
  loan_id        INT AUTO_INCREMENT PRIMARY KEY,
  customer_id    INT NOT NULL,
  branch_id      INT NOT NULL,
  amount         DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  interest_rate  DECIMAL(5,2) NOT NULL,
  start_date     DATE DEFAULT (CURRENT_DATE),
  status         VARCHAR(10) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','CLOSED')),
  FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
  FOREIGN KEY (branch_id)   REFERENCES Branch(branch_id)
) ENGINE=InnoDB AUTO_INCREMENT=9000;

CREATE TABLE Loan_Payment (
  payment_id   INT AUTO_INCREMENT PRIMARY KEY,
  loan_id      INT NOT NULL,
  amount       DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  pay_date     DATE DEFAULT (CURRENT_DATE),
  FOREIGN KEY (loan_id) REFERENCES Loan(loan_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Account_Audit (
  audit_id     INT AUTO_INCREMENT PRIMARY KEY,
  account_no   INT,
  old_balance  DECIMAL(15,2),
  new_balance  DECIMAL(15,2),
  operation    VARCHAR(10),
  userid       VARCHAR(80),
  op_date      DATETIME
) ENGINE=InnoDB;

CREATE INDEX idx_account_cust ON Account(customer_id);
CREATE INDEX idx_txn_account  ON Bank_Transaction(account_no, txn_date);
CREATE INDEX idx_loan_cust    ON Loan(customer_id);
CREATE INDEX idx_emp_branch   ON Employee(branch_id);

-- Views (Unit 3)
CREATE OR REPLACE VIEW v_customer_accounts AS
  SELECT c.customer_id, c.name, a.account_no, a.acc_type, a.balance, b.branch_name
  FROM Customer c JOIN Account a ON c.customer_id = a.customer_id
                  JOIN Branch b  ON a.branch_id  = b.branch_id;

CREATE OR REPLACE VIEW v_loan_outstanding AS
  SELECT l.loan_id, c.name, l.amount,
         IFNULL(SUM(p.amount),0) AS paid,
         l.amount - IFNULL(SUM(p.amount),0) AS outstanding
  FROM Loan l JOIN Customer c ON c.customer_id = l.customer_id
              LEFT JOIN Loan_Payment p ON p.loan_id = l.loan_id
  GROUP BY l.loan_id, c.name, l.amount;
