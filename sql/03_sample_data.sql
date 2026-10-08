
USE bank_db;

INSERT INTO Branch (branch_name, city, assets) VALUES
 ('Main Branch','Chennai',0), ('Anna Nagar','Chennai',0),
 ('Koramangala','Bengaluru',0), ('Banjara Hills','Hyderabad',0);

INSERT INTO Customer (name, dob, phone, email, address) VALUES
 ('Rajesh Kumar','1990-04-12','9000000001','rajesh@mail.com','Chennai'),
 ('Priya Sharma','1995-08-23','9000000002','priya@mail.com','Bengaluru'),
 ('Arun Das','1988-01-05','9000000003','arun@mail.com','Hyderabad'),
 ('Meena Iyer','1992-11-30','9000000004','meena@mail.com','Chennai'),
 ('Sanjay Rao','1980-06-18','9000000005','sanjay@mail.com','Bengaluru'),
 ('Neha Singh','1998-02-14','9000000006','neha@mail.com','Chennai');

INSERT INTO Employee (name, position, salary, branch_id, manager_id) VALUES
 ('Vikram Nair','Manager',90000,100,NULL),
 ('Anita Rao','Manager',85000,101,500),
 ('Karthik S','Cashier',35000,100,500),
 ('Divya M','Clerk',30000,101,501),
 ('Farhan Ali','Manager',82000,102,500),
 ('Lakshmi P','Loan Officer',45000,103,500);

INSERT INTO Account (customer_id, branch_id, acc_type) VALUES
 (1000,100,'SAVINGS'), (1001,102,'SAVINGS'), (1002,103,'CURRENT'),
 (1003,101,'SAVINGS'), (1004,102,'FIXED'),   (1000,100,'CURRENT');

INSERT INTO Bank_Transaction (account_no, txn_type, amount, description) VALUES
 (10001,'DEPOSIT',50000,'Opening deposit'),
 (10002,'DEPOSIT',75000,'Opening deposit'),
 (10003,'DEPOSIT',120000,'Opening deposit'),
 (10004,'DEPOSIT',20000,'Opening deposit'),
 (10005,'DEPOSIT',200000,'Fixed deposit'),
 (10006,'DEPOSIT',15000,'Opening deposit'),
 (10001,'WITHDRAWAL',5000,'ATM'),
 (10002,'WITHDRAWAL',10000,'Cheque');

INSERT INTO Loan (customer_id, branch_id, amount, interest_rate, start_date, status) VALUES
 (1000,100,500000,8.5,'2025-01-10','OPEN'),
 (1002,103,300000,9.0,'2025-03-15','OPEN'),
 (1004,102,150000,7.5,'2024-06-01','OPEN');

INSERT INTO Loan_Payment (loan_id, amount, pay_date) VALUES
 (9000,25000,'2025-02-10'), (9000,25000,'2025-03-10'),
 (9001,30000,'2025-04-15'), (9002,150000,'2025-01-01');
UPDATE Loan SET status='CLOSED' WHERE loan_id=9002;
