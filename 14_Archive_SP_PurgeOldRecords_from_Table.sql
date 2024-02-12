USE DBA
GO

CREATE PROCEDURE [dbo].[PurgeOldRecords]
    @DatabaseName nvarchar(128),
    @TableName nvarchar(128),
    @DateColumnName nvarchar(128),
    @BatchSize int,
    @OlderThanDays int
AS
BEGIN
    DECLARE @CutoffDate date;
    SET @CutoffDate = DATEADD(DAY, -@OlderThanDays, GETDATE());

    -- Create a temporary table to store IDs with an index
    CREATE TABLE #TempTableToDelete (ID int PRIMARY KEY CLUSTERED);

    -- Find the primary key column
    DECLARE @PrimaryKeyColumn nvarchar(128);
    SELECT @PrimaryKeyColumn = COLUMN_NAME
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
    WHERE OBJECT_NAME(OBJECT_ID(@TableName)) = @TableName;

    -- Check if a primary key exists
    IF @PrimaryKeyColumn IS NOT NULL
    BEGIN
        -- Load IDs older than 90 days into the temporary table
        DECLARE @LoadIDsSQL nvarchar(max);
        SET @LoadIDsSQL = 'INSERT INTO #TempTableToDelete (ID)
            SELECT TOP (@BatchSize) ' + QUOTENAME(@PrimaryKeyColumn) + '
            FROM ' + QUOTENAME(@DatabaseName) + '..' + QUOTENAME(@TableName) + '
            WHERE ' + QUOTENAME(@DateColumnName) + ' < @CutoffDate';

        EXEC sp_executesql @LoadIDsSQL,
                           N'@CutoffDate DATE, @BatchSize INT',
                           @CutoffDate,
                           @BatchSize;

        -- Delete data by joining with the temporary table
        DECLARE @DeleteSQL nvarchar(max);
        SET @DeleteSQL
            = 'DELETE t
            FROM ' + QUOTENAME(@DatabaseName) + '..' + QUOTENAME(@TableName)
              + ' t
            INNER JOIN #TempTableToDelete tmp WITH (NOLOCK) ON t.' + QUOTENAME(@PrimaryKeyColumn) + ' = tmp.ID';

        EXEC sp_executesql @DeleteSQL;

        -- Drop the temporary table
        DROP TABLE #TempTableToDelete;
    END
END;
