USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[table_to_html]    Script Date: 1/17/2024 4:08:46 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[table_to_html] (
  @tablename sysname,
  @html xml OUTPUT,
  @order varchar(4) = 'ASC'
) AS
BEGIN
  DECLARE
    @sql nvarchar(max),
    @cols nvarchar(max),
    @htmlcols xml,
    @htmldata xml,
    @object_id int = OBJECT_ID('[tempdb].[dbo].'+QUOTENAME(@tablename));

  IF @order <> 'DESC' SET @order = 'ASC';

  SELECT @cols = COALESCE(@cols+',','')+QUOTENAME([name])+' '+@order
  FROM tempdb.sys.columns
  WHERE object_id = @object_id
  ORDER BY [column_id];

  SET @htmlcols = (
    SELECT [name] AS [th]
    FROM tempdb.sys.columns
    WHERE object_id = @object_id
    ORDER BY [column_id] FOR XML PATH(''),ROOT('tr')
  );

  SELECT @sql = COALESCE(@sql+',','SELECT @htmldata = (SELECT ')+'ISNULL(LTRIM('+QUOTENAME([name])+'),''NULL'') AS [td]'
  FROM tempdb.sys.columns
  WHERE object_id = @object_id
  ORDER BY [column_id];

  SET @sql = @sql + ' FROM '+QUOTENAME(@tablename)+' ORDER BY '+@cols+' FOR XML RAW(''tr''), ELEMENTS)';

  EXEC sp_executesql @sql, N'@htmldata xml OUTPUT', @htmldata OUTPUT

  SET @html = (SELECT @htmlcols,@htmldata FOR XML PATH('table'));
END



GO


