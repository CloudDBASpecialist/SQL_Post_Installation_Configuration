-- Drop and create the temporary table
IF OBJECT_ID('tempdb..#usertable', 'U') IS NOT NULL
    DROP TABLE #usertable;

CREATE TABLE #usertable (Username VARCHAR(MAX));

INSERT INTO #usertable (Username)
VALUES
    ('user01'),
    ('user02'),
    ('user03'),
    ('user04'),
    ('user05'),
    ('user06'),
    ('user07'),
    ('user08'),
    ('user09');

DECLARE @user NVARCHAR(50),
        @query1 NVARCHAR(200),
        @query2 NVARCHAR(200);

DECLARE user_cursor CURSOR FOR
    SELECT username
    FROM #usertable;

OPEN user_cursor;

FETCH NEXT FROM user_cursor INTO @user;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @user = DEFAULT_DOMAIN() + '\' + @user; -- Assuming @user does not include domain already
    SET @query1 = N'CREATE LOGIN [' + @user + N'] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english];';
    SET @query2 = N'ALTER SERVER ROLE [sysadmin] ADD MEMBER [' + @user + N'] ;';

    IF NOT EXISTS (SELECT name FROM sys.syslogins WHERE name = @user)
    BEGIN
        EXEC sp_executesql @query1;
        EXEC sp_executesql @query2;
        PRINT @user + ' Created';
    END
    ELSE
    BEGIN
        PRINT 'User ' + @user + ' Exists';
    END

    FETCH NEXT FROM user_cursor INTO @user;
END

CLOSE user_cursor;
DEALLOCATE user_cursor;
