DECLARE @DbName NVARCHAR(128) = 'DBA';
DECLARE @SubdirPath NVARCHAR(256) = 'DBA1';

-- Declare the temporary table outside the dynamic SQL
CREATE TABLE #ResultSet (Directory VARCHAR(200));

-- Use parameterized dynamic SQL to get subdirectories
DECLARE @Sql NVARCHAR(MAX) = 'INSERT INTO #ResultSet EXEC master.dbo.xp_subdirs ''D:\'';';
EXEC sp_executesql @Sql;

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @DbName)
BEGIN
    IF EXISTS (SELECT 1 FROM #ResultSet WHERE Directory = @SubdirPath)
    BEGIN
        CREATE DATABASE [DBA]
        ON PRIMARY 
        ( 
            NAME = N'DBA', 
            FILENAME = N'D:\DBA1\dba.mdf', 
            SIZE = 524288KB, 
            FILEGROWTH = 131072KB 
        );

        PRINT 'Database "DBA" created.';
    END
    ELSE
    BEGIN
        PRINT 'Database "DBA" already exists.';
    END
END
ELSE
BEGIN
    PRINT 'Database "DBA" already exists.';
END

-- Drop the temporary table
DROP TABLE #ResultSet;





USE [master]
GO
ALTER DATABASE [DBA] SET RECOVERY SIMPLE WITH NO_WAIT
GO
