USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[table_to_html]    Script Date: 1/25/2024 12:37:36 PM ******/
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







USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[email_table]    Script Date: 1/17/2024 4:08:29 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[email_table] (
  @tablename sysname,
  @recipients nvarchar(max),
  @email_recipient_cc nvarchar(max) = NULL,
  @subject nvarchar(max) = '',
  @order varchar(4) = 'ASC'
) AS
BEGIN
  IF OBJECT_ID('[tempdb].[dbo].'+QUOTENAME(@tablename)) IS NULL RAISERROR('Table does not exist. [dbo].[email_table] only works with temporary tables.',16,1);

  DECLARE @style varchar(max) = 'table {border-collapse:collapse;} td,th {white-space:nowrap;border:solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;} th {border-bottom-width:2px;}';

  DECLARE @table1 xml;
  EXEC [dbo].[table_to_html] @tablename, @table1 OUTPUT, @order;

  DECLARE @email_body AS nvarchar(max) = (
    SELECT
      (SELECT
        @style AS [style]
       FOR XML PATH('head'),TYPE),
      (SELECT
        @table1
       FOR XML PATH('body'),TYPE)
    FOR XML PATH('html')
  );

  EXEC msdb.dbo.sp_send_dbmail
    @recipients = @recipients,
    @copy_recipients = @email_recipient_cc,
    @subject = @subject,
    @body = @email_body,
	@profile_name= 'DBA',
    @body_format = 'html';

END


GO


