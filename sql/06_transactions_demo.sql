-- ============================================================
-- Transaction Management demo | Unit 5
-- ============================================================
-- Atomicity: all or nothing
SET TRANSACTION NAME 'xfer_demo';
UPDATE Account SET balance = balance - 1000 WHERE account_no = 10001;
SAVEPOINT s1;
UPDATE Account SET balance = balance + 1000 WHERE account_no = 10002;
ROLLBACK TO s1;     -- undo only second update
COMMIT;             -- first update is made durable (for demo of savepoint)

-- Isolation levels
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;   -- Oracle default
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
ROLLBACK;

-- Lock demo (open two sessions)
-- Session 1:  SELECT * FROM Account WHERE account_no=10001 FOR UPDATE;
-- Session 2:  UPDATE Account SET balance=balance+1 WHERE account_no=10001;  -- waits (row lock)
-- Session 1:  COMMIT;   -- session 2 proceeds

-- Deadlock demo (two sessions)
-- S1: UPDATE Account SET balance=balance WHERE account_no=10001;
-- S2: UPDATE Account SET balance=balance WHERE account_no=10002;
-- S1: UPDATE Account SET balance=balance WHERE account_no=10002;  -- waits
-- S2: UPDATE Account SET balance=balance WHERE account_no=10001;  -- ORA-00060 deadlock detected

-- Calls
BEGIN transfer(10003, 10004, 5000); END;
/
BEGIN transfer(10004, 10003, 99999999); END;   -- fails: insufficient balance, rolled back
/
