-- Login: Create one SQL Login to manage all services 
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'[P-SQL-DBA-DB]')
BEGIN
CREATE LOGIN [P-SQL-DBA-DB] WITH 
PASSWORD = ,
 SID = , 
DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
    PRINT 'Login "P-SQL-DBA-DB" created.';
END
ELSE
BEGIN
    PRINT 'Login "[P-SQL-DBA-DB]" already exists.';
END
go
 ALTER SERVER ROLE [sysadmin] ADD MEMBER [P-SQL-DBA-DB]
GO
