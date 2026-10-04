-- ============================================================
-- Bank Management System  |  CSE3001 DBMS  |  Oracle SQL (DDL)
-- Syllabus: Unit 3 (DDL, constraints, sequences, indexes, views)
-- ============================================================
DROP TABLE Loan_Payment CASCADE CONSTRAINTS;
DROP TABLE Loan CASCADE CONSTRAINTS;
DROP TABLE Bank_Transaction CASCADE CONSTRAINTS;
DROP TABLE Account_Audit CASCADE CONSTRAINTS;
DROP TABLE Account CASCADE CONSTRAINTS;
DROP TABLE Employee CASCADE CONSTRAINTS;
DROP TABLE Customer CASCADE CONSTRAINTS;
DROP TABLE Branch CASCADE CONSTRAINTS;

CREATE TABLE Branch (
  branch_id    NUMBER PRIMARY KEY,
  branch_name  VARCHAR2(50) NOT NULL UNIQUE,
  city         VARCHAR2(40) NOT NULL,
  assets       NUMBER(15,2) DEFAULT 0 CHECK (assets >= 0)
);

CREATE TABLE Customer (
  customer_id  NUMBER PRIMARY KEY,
  name         VARCHAR2(60) NOT NULL,
  dob          DATE,
  phone        VARCHAR2(15) UNIQUE,
  email        VARCHAR2(80) UNIQUE,
  address      VARCHAR2(120)
);

CREATE TABLE Employee (
  emp_id       NUMBER PRIMARY KEY,
  name         VARCHAR2(60) NOT NULL,
  position     VARCHAR2(30) NOT NULL,
  salary       NUMBER(10,2) CHECK (salary > 0),
  branch_id    NUMBER NOT NULL REFERENCES Branch(branch_id),
  manager_id   NUMBER REFERENCES Employee(emp_id)   -- self reference (boss)
);

CREATE TABLE Account (
  account_no   NUMBER PRIMARY KEY,
  customer_id  NUMBER NOT NULL REFERENCES Customer(customer_id),
  branch_id    NUMBER NOT NULL REFERENCES Branch(branch_id),
  acc_type     VARCHAR2(10) NOT NULL CHECK (acc_type IN ('SAVINGS','CURRENT','FIXED')),
  balance      NUMBER(15,2) DEFAULT 0 CHECK (balance >= 0),
  open_date    DATE DEFAULT SYSDATE,
  status       VARCHAR2(10) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','CLOSED','FROZEN'))
);

CREATE TABLE Bank_Transaction (
  txn_id       NUMBER PRIMARY KEY,
  account_no   NUMBER NOT NULL REFERENCES Account(account_no),
  txn_type     VARCHAR2(12) NOT NULL CHECK (txn_type IN ('DEPOSIT','WITHDRAWAL')),
  amount       NUMBER(15,2) NOT NULL CHECK (amount > 0),
  txn_date     DATE DEFAULT SYSDATE,
  description  VARCHAR2(100)
);

CREATE TABLE Loan (
  loan_id        NUMBER PRIMARY KEY,
  customer_id    NUMBER NOT NULL REFERENCES Customer(customer_id),
  branch_id      NUMBER NOT NULL REFERENCES Branch(branch_id),
  amount         NUMBER(15,2) NOT NULL CHECK (amount > 0),
  interest_rate  NUMBER(5,2) NOT NULL,
  start_date     DATE DEFAULT SYSDATE,
  status         VARCHAR2(10) DEFAULT 'OPEN' CHECK (status IN ('OPEN','CLOSED'))
);

CREATE TABLE Loan_Payment (
  payment_id   NUMBER PRIMARY KEY,
  loan_id      NUMBER NOT NULL REFERENCES Loan(loan_id) ON DELETE CASCADE,
  amount       NUMBER(15,2) NOT NULL CHECK (amount > 0),
  pay_date     DATE DEFAULT SYSDATE
);

CREATE TABLE Account_Audit (
  audit_id     NUMBER PRIMARY KEY,
  account_no   NUMBER,
  old_balance  NUMBER(15,2),
  new_balance  NUMBER(15,2),
  operation    VARCHAR2(10),
  userid       VARCHAR2(30),
  op_date      DATE
);

-- Sequences
CREATE SEQUENCE seq_branch   START WITH 100;
CREATE SEQUENCE seq_customer START WITH 1000;
CREATE SEQUENCE seq_employee START WITH 500;
CREATE SEQUENCE seq_account  START WITH 10001;
CREATE SEQUENCE seq_txn      START WITH 1;
CREATE SEQUENCE seq_loan     START WITH 9000;
CREATE SEQUENCE seq_payment  START WITH 1;
CREATE SEQUENCE seq_audit    START WITH 1;

-- Indexes (Unit 4: indexing)
CREATE INDEX idx_account_cust ON Account(customer_id);
CREATE INDEX idx_txn_account  ON Bank_Transaction(account_no, txn_date);
CREATE INDEX idx_loan_cust    ON Loan(customer_id);
CREATE INDEX idx_emp_branch   ON Employee(branch_id);

-- Synonym
CREATE OR REPLACE SYNONYM txns FOR Bank_Transaction;

-- Views (Unit 3)
CREATE OR REPLACE VIEW v_customer_accounts AS
  SELECT c.customer_id, c.name, a.account_no, a.acc_type, a.balance, b.branch_name
  FROM Customer c JOIN Account a ON c.customer_id = a.customer_id
                  JOIN Branch b  ON a.branch_id  = b.branch_id;

CREATE OR REPLACE VIEW v_loan_outstanding AS
  SELECT l.loan_id, c.name, l.amount,
         NVL(SUM(p.amount),0) AS paid,
         l.amount - NVL(SUM(p.amount),0) AS outstanding
  FROM Loan l JOIN Customer c ON c.customer_id = l.customer_id
              LEFT JOIN Loan_Payment p ON p.loan_id = l.loan_id
  GROUP BY l.loan_id, c.name, l.amount;
