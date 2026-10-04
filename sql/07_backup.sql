-- ============================================================
-- Backup scripts | Lab Exp 4 (backup) | Unit 5 (recovery)
-- ============================================================
-- (A) SQL Server: backup ALL user databases
DECLARE @name VARCHAR(100), @path VARCHAR(256) = 'C:\Backup\', @file VARCHAR(256),
        @date VARCHAR(20) = CONVERT(VARCHAR(20), GETDATE(), 112);
DECLARE db_cursor CURSOR FOR
  SELECT name FROM master.dbo.sysdatabases WHERE name NOT IN ('master','model','msdb','tempdb');
OPEN db_cursor; FETCH NEXT FROM db_cursor INTO @name;
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @file = @path + @name + '_' + @date + '.BAK';
  BACKUP DATABASE @name TO DISK = @file;
  FETCH NEXT FROM db_cursor INTO @name;
END
CLOSE db_cursor; DEALLOCATE db_cursor;

-- (B) Oracle (shell):
--   expdp bankuser/password schemas=BANKUSER directory=DATA_PUMP_DIR dumpfile=bank_%U.dmp logfile=bank_exp.log
--   Restore: impdp bankuser/password schemas=BANKUSER directory=DATA_PUMP_DIR dumpfile=bank_%U.dmp
