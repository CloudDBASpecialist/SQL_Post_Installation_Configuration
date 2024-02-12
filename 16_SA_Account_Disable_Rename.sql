DECLARE @serverhostname NVARCHAR(50)
SELECT @serverhostname = @@SERVERNAME

DECLARE @serviceNickName NVARCHAR(5)
SET @serviceNickName = SUBSTRING(@serverhostname, 5, 3)
--SELECT @serviceNickName

DECLARE @newSA NVARCHAR(10)
SET @newSA = 'sa-' + @serviceNickName
--SELECT @newSA

IF NOT EXISTS (
        SELECT name
        FROM sys.server_principals
        WHERE sid = 0x01
        AND name = @newSA
    )
BEGIN
    IF EXISTS (
            SELECT name
            FROM sys.server_principals
            WHERE sid = 0x01
        )
    BEGIN
        DECLARE @tsql NVARCHAR(MAX)
        SET @tsql = 'ALTER LOGIN ' + QUOTENAME(SUSER_NAME(0x01)) + ' DISABLE'
        EXEC (@tsql)

        SET @tsql = 'ALTER LOGIN sa WITH NAME = [' + @newSA + ']'
        EXEC (@tsql)
    END
END
