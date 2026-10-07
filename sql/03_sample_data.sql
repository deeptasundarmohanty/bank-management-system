USE banking_db;

INSERT INTO Branch (branch_id, branch_name, city, assets) VALUES
(100, 'Main Branch', 'Chennai', 0),
(101, 'Anna Nagar', 'Chennai', 0),
(102, 'Koramangala', 'Bengaluru', 0),
(103, 'Banjara Hills', 'Hyderabad', 0);



INSERT INTO Customer
(customer_id, name, dob, phone, email, address)
VALUES
(1000, 'Rajesh Kumar', '1990-04-12', '9000000001',
 'rajesh@mail.com', 'Chennai'),

(1001, 'Priya Sharma', '1995-08-23', '9000000002',
 'priya@mail.com', 'Bengaluru'),

(1002, 'Arun Das', '1988-01-05', '9000000003',
 'arun@mail.com', 'Hyderabad'),

(1003, 'Meena Iyer', '1992-11-30', '9000000004',
 'meena@mail.com', 'Chennai'),

(1004, 'Sanjay Rao', '1980-06-18', '9000000005',
 'sanjay@mail.com', 'Bengaluru'),

(1005, 'Neha Singh', '1998-02-14', '9000000006',
 'neha@mail.com', 'Chennai');


INSERT INTO Employee
(emp_id, name, `position`, salary, branch_id, manager_id)
VALUES
(500, 'Vikram Nair', 'Manager', 90000, 100, NULL),

(501, 'Anita Rao', 'Manager', 85000, 101, 500),

(502, 'Karthik S', 'Cashier', 35000, 100, 500),

(503, 'Divya M', 'Clerk', 30000, 101, 501),

(504, 'Farhan Ali', 'Manager', 82000, 102, 500),

(505, 'Lakshmi P', 'Loan Officer', 45000, 103, 500);


INSERT INTO Account
(account_no, customer_id, branch_id, acc_type, balance)
VALUES
(10001, 1000, 100, 'SAVINGS', 0),

(10002, 1001, 102, 'SAVINGS', 0),

(10003, 1002, 103, 'CURRENT', 0),

(10004, 1003, 101, 'SAVINGS', 0),

(10005, 1004, 102, 'FIXED', 0),

(10006, 1000, 100, 'CURRENT', 0);



INSERT INTO Bank_Transaction
(txn_id, account_no, txn_type, amount, description)
VALUES
(1, 10001, 'DEPOSIT', 50000, 'Opening deposit'),

(2, 10002, 'DEPOSIT', 75000, 'Opening deposit'),

(3, 10003, 'DEPOSIT', 120000, 'Opening deposit'),

(4, 10004, 'DEPOSIT', 20000, 'Opening deposit'),

(5, 10005, 'DEPOSIT', 200000, 'Fixed deposit'),

(6, 10006, 'DEPOSIT', 15000, 'Opening deposit'),

(7, 10001, 'WITHDRAWAL', 5000, 'ATM'),

(8, 10002, 'WITHDRAWAL', 10000, 'Cheque');


INSERT INTO Loan
(loan_id, customer_id, branch_id, amount,
 interest_rate, start_date, status)
VALUES
(9000, 1000, 100, 500000, 8.5, '2025-01-10', 'OPEN'),

(9001, 1002, 103, 300000, 9.0, '2025-03-15', 'OPEN'),

(9002, 1004, 102, 150000, 7.5, '2024-06-01', 'OPEN');


INSERT INTO Loan_Payment
(payment_id, loan_id, amount, pay_date)
VALUES
(1, 9000, 25000, '2025-02-10'),

(2, 9000, 25000, '2025-03-10'),

(3, 9001, 30000, '2025-04-15'),

(4, 9002, 150000, '2025-01-01');


UPDATE Loan
SET status = 'CLOSED'
WHERE loan_id = 9002;


COMMIT;


SELECT * FROM Branch;
SELECT * FROM Customer;
SELECT * FROM Employee;
SELECT * FROM Account;
SELECT * FROM Bank_Transaction;
SELECT * FROM Loan;
SELECT * FROM Loan_Payment;
