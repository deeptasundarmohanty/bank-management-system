-- Sample data. Accounts start at 0; deposits (via trigger) fill balances.
-- Run AFTER 01_schema.sql and 02_triggers.sql
INSERT INTO Branch VALUES (seq_branch.NEXTVAL,'Main Branch','Chennai',0);
INSERT INTO Branch VALUES (seq_branch.NEXTVAL,'Anna Nagar','Chennai',0);
INSERT INTO Branch VALUES (seq_branch.NEXTVAL,'Koramangala','Bengaluru',0);
INSERT INTO Branch VALUES (seq_branch.NEXTVAL,'Banjara Hills','Hyderabad',0);

INSERT INTO Customer VALUES (1000,'Rajesh Kumar',DATE '1990-04-12','9000000001','rajesh@mail.com','Chennai');
INSERT INTO Customer VALUES (1001,'Priya Sharma',DATE '1995-08-23','9000000002','priya@mail.com','Bengaluru');
INSERT INTO Customer VALUES (1002,'Arun Das',DATE '1988-01-05','9000000003','arun@mail.com','Hyderabad');
INSERT INTO Customer VALUES (1003,'Meena Iyer',DATE '1992-11-30','9000000004','meena@mail.com','Chennai');
INSERT INTO Customer VALUES (1004,'Sanjay Rao',DATE '1980-06-18','9000000005','sanjay@mail.com','Bengaluru');
INSERT INTO Customer VALUES (1005,'Neha Singh',DATE '1998-02-14','9000000006','neha@mail.com','Chennai');

INSERT INTO Employee VALUES (500,'Vikram Nair','Manager',90000,100,NULL);
INSERT INTO Employee VALUES (501,'Anita Rao','Manager',85000,101,500);
INSERT INTO Employee VALUES (502,'Karthik S','Cashier',35000,100,500);
INSERT INTO Employee VALUES (503,'Divya M','Clerk',30000,101,501);
INSERT INTO Employee VALUES (504,'Farhan Ali','Manager',82000,102,500);
INSERT INTO Employee VALUES (505,'Lakshmi P','Loan Officer',45000,103,500);

INSERT INTO Account (account_no,customer_id,branch_id,acc_type,balance) VALUES (10001,1000,100,'SAVINGS',0);
INSERT INTO Account (account_no,customer_id,branch_id,acc_type,balance) VALUES (10002,1001,102,'SAVINGS',0);
INSERT INTO Account (account_no,customer_id,branch_id,acc_type,balance) VALUES (10003,1002,103,'CURRENT',0);
INSERT INTO Account (account_no,customer_id,branch_id,acc_type,balance) VALUES (10004,1003,101,'SAVINGS',0);
INSERT INTO Account (account_no,customer_id,branch_id,acc_type,balance) VALUES (10005,1004,102,'FIXED',0);
INSERT INTO Account (account_no,customer_id,branch_id,acc_type,balance) VALUES (10006,1000,100,'CURRENT',0);
-- note: sequence seq_account starts at 10001; bump it so new accounts don't collide
DECLARE n NUMBER; BEGIN FOR i IN 1..6 LOOP n := seq_account.NEXTVAL; END LOOP; END;
/

INSERT INTO Bank_Transaction (txn_id,account_no,txn_type,amount,description) VALUES (seq_txn.NEXTVAL,10001,'DEPOSIT',50000,'Opening deposit');
INSERT INTO Bank_Transaction (txn_id,account_no,txn_type,amount,description) VALUES (seq_txn.NEXTVAL,10002,'DEPOSIT',75000,'Opening deposit');
INSERT INTO Bank_Transaction (txn_id,account_no,txn_type,amount,description) VALUES (seq_txn.NEXTVAL,10003,'DEPOSIT',120000,'Opening deposit');
INSERT INTO Bank_Transaction (txn_id,account_no,txn_type,amount,description) VALUES (seq_txn.NEXTVAL,10004,'DEPOSIT',20000,'Opening deposit');
INSERT INTO Bank_Transaction (txn_id,account_no,txn_type,amount,description) VALUES (seq_txn.NEXTVAL,10005,'DEPOSIT',200000,'Fixed deposit');
INSERT INTO Bank_Transaction (txn_id,account_no,txn_type,amount,description) VALUES (seq_txn.NEXTVAL,10006,'DEPOSIT',15000,'Opening deposit');
INSERT INTO Bank_Transaction (txn_id,account_no,txn_type,amount,description) VALUES (seq_txn.NEXTVAL,10001,'WITHDRAWAL',5000,'ATM');
INSERT INTO Bank_Transaction (txn_id,account_no,txn_type,amount,description) VALUES (seq_txn.NEXTVAL,10002,'WITHDRAWAL',10000,'Cheque');

INSERT INTO Loan VALUES (seq_loan.NEXTVAL,1000,100,500000,8.5,DATE '2025-01-10','OPEN');
INSERT INTO Loan VALUES (seq_loan.NEXTVAL,1002,103,300000,9.0,DATE '2025-03-15','OPEN');
INSERT INTO Loan VALUES (seq_loan.NEXTVAL,1004,102,150000,7.5,DATE '2024-06-01','OPEN');

INSERT INTO Loan_Payment VALUES (seq_payment.NEXTVAL,9000,25000,DATE '2025-02-10');
INSERT INTO Loan_Payment VALUES (seq_payment.NEXTVAL,9000,25000,DATE '2025-03-10');
INSERT INTO Loan_Payment VALUES (seq_payment.NEXTVAL,9001,30000,DATE '2025-04-15');
INSERT INTO Loan_Payment VALUES (seq_payment.NEXTVAL,9002,150000,DATE '2025-01-01');
UPDATE Loan SET status='CLOSED' WHERE loan_id=9002;
COMMIT;
