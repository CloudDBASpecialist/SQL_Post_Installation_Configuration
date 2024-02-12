USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[DBA_Export_Table_Data_To_CSV_File_in_Batches]    Script Date: 1/17/2024 4:05:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[DBA_Export_Table_Data_To_CSV_File_in_Batches]
@ptableName nvarchar (500),
@pFileOutputPath varchar(200) ='C:\Temp',
@pFileOutPutPrefix varchar(200) = 'OutPutFile_',
@pBatchSize	bigint = 1000000 ,
@pServerName varchar (100) = 'localhost',
@pDatabaseName varchar(100) = 'tempdb'
/*

use tempdb
go

exec sp_configure 'xp_cmdshell' ,1 
go
reconfigure
go

EXEC DBA.DBO.DBA_Export_Table_Data_To_CSV_File_in_Batches 
@ptableName = '##t22' ,
@pFileOutputPath ='C:\Temp',
@pFileOutPutPrefix = 'NSPOutPutFile_',
@pBatchSize	= 1000
GO
exec sp_configure 'xp_cmdshell' ,0
go
reconfigure
go


SELECT top 10000 * into ##t22 FROM ##t2

select * from tempdb.sys.columns where object_id = OBJECT_ID('##T22')
*/
AS 
BEGIN 
	declare @ServerName varchar (100) = 'localhost'
	DECLARE @databaseName varchar(100) = 'tempdb'
	DECLARE @tableName	nvarchar (500) = '##t2' -- if its a permanent table then use DBNAME.SCHEMANAME.TABLENAME e.g. DBA.dbo.testtableforoutput
	DECLARE @iTotalRowsinTable	bigint
	DECLARE @SQL nvarchar (max)
	DECLARE @SQLforxpcmdshell varchar (8000)
	DECLARE @ParamDefinition	nvarchar(max)
	DECLARE @iBatchSize	bigint = 1000000 --1 million rows
	DECLARE @sFileOutputPath varchar(200) ='C:\Temp'
	DECLARE @sFileOutPutPrefix varchar(200) = 'NSPOutPutFile_'
	DECLARE @sFileExtension	varchar(10) = '.csv'
	DECLARE @SQLforSQLCMD	varchar(8000)
	DECLARE @iRemainingRows bigint 
	DECLARE @iIterations	int
	DECLARE @iCounter	int = 0
	DECLARE @sCounter	varchar(10) ='0'
	DECLARE @sOFFSETValue varchar(50)
	DECLARE @sDelimiter varchar(5) = ';'
	DECLARE @sHeaderDataFileName varchar(500)
	DECLARE @sDataHoldingFileName varchar (500)

	if (@ptableName	is null)
	begin 
		SELECT 'NO TABLE NAME PROVIDED'
		GOTO UNABLETOPROCEED
	end

	begin try
	
		SET @SQL = 'SELECT top 1 * FROM '+@ptableName
		print @SQL
		EXEC sp_executesql @SQL

	end try

	begin catch
		SELECT 'TABLE NAME IS NOT ACCESSIBLE'
		GOTO UNABLETOPROCEED
	end catch


	SET @tableName			=	@ptableName			
	SET @sFileOutputPath 	=	@pFileOutputPath 	
	SET @sFileOutPutPrefix 	=	@pFileOutPutPrefix 	
	SET @iBatchSize			=	@pBatchSize			
	SET @ServerName 		=	@pServerName 		
	SET @DatabaseName 		=	@pDatabaseName 		

	SET @sFileOutPutPrefix = @sFileOutPutPrefix +'_'+ REPLACE (@tableName,'##','') +'_'
	SET @sFileOutPutPrefix = REPLACE(@sFileOutPutPrefix ,'dba.dbo.','')
	SET @sHeaderDataFileName = REPLACE(@sFileOutPutPrefix ,'_','')+'_HEADERS.csv'
	SET @sDataHoldingFileName = 'Data_only_'+REPLACE(@sFileOutPutPrefix ,'_','')

	SET @ParamDefinition = N'@RetValOUT int output'

	SELECT @SQL = N'select @RetValOUT = count (1) from ' + @tableName	
	exec sp_executesql @SQL , @ParamDefinition , @RetValOUT = @iTotalRowsinTable	 OUTPUT
	SELECT @iTotalRowsinTable
	SET @iRemainingRows = @iTotalRowsinTable


	SELECT @iIterations = @iTotalRowsinTable / @iBatchSize
	SELECT @iIterations 

	SET @SQL = ''

	SET @SQL = 'set nocount on; SELECT * FROM ' + @tableName + ' ORDER BY 1 OFFSET 0 ROWS FETCH NEXT ' + CAST (@iBatchSize as varchar) + ' ROWS ONLY ;'

	--print @SQL


		--Generate column names as a recordset
	declare @columns varchar(8000)
	select 
		@columns=coalesce(@columns+',','')+column_name+' as '+column_name 
	from 
		information_schema.columns
	where 
		--table_name='##t22'--@tableName
		table_name= @tableName
		OR table_name= REPLACE(@tableName,'dba.dbo.','')
	SELECT @columns
	select @columns=''''''+replace(replace(@columns,' as ',''''' as '),',',',''''')

	--Generate column names in the passed EXCEL file
	--set @SQLforSQLCMD='bcp " select * from (select '+isnull(@columns,' 1 ')+') as t" queryout "'+@sFileOutputPath+'\'+@sHeaderDataFileName+'" -c'' '
	--print @SQLforSQLCMD
	--print 'generated the columns'
	--exec xp_cmdshell @SQLforSQLCMD 
	SET @SQLforSQLCMD = ''





	while @iRemainingRows > 0 OR @iCounter	< @iIterations
	BEGIN 
	
		SET @sOFFSETValue = CAST ((@iBatchSize*@iCounter) as varchar)
		SET @SQL = N'set nocount on; SELECT * FROM ' + @tableName + N' ORDER BY 1 OFFSET '+@sOFFSETValue+' ROWS FETCH NEXT ' + CAST (@iBatchSize as nvarchar) + N' ROWS ONLY ;'
	
		SET @SQLforxpcmdshell = CAST(@SQL AS VARCHAR(8000))
		SET @sCounter = CAST(@iCounter as varchar(10))
		--SET @SQLforSQLCMD = 'SQLCMD -S '+@ServerName + ' -E -d ' +@databaseName+ ' -Q"'+ @SQLforxpcmdshell  +'" -o ' + @sFileOutputPath+'\'+@sDataHoldingFileName +@sFileExtension + ' -s"'+@sDelimiter+'" -W -u '
		SET @SQLforSQLCMD = 'SQLCMD -S '+@ServerName + ' -E -d ' +@databaseName+ ' -Q"'+ @SQLforxpcmdshell  +'" -o ' + @sFileOutputPath+'\'+@sFileOutPutPrefix+@sCounter +@sFileExtension + ' -s"'+@sDelimiter+'" -W -u '



		begin try 
			exec xp_cmdshell @SQLforSQLCMD 
		end try 
		begin catch SELECT 'DISCARD THE OUTPUT FILES SELECT SOME ERROR OCCURRED IN THE EXPORT ' end catch 
		
		--Copy the headers file to rename to have actual file and then be appended

		--set @SQLforSQLCMD= 'copy '+@sFileOutputPath+'\'+@sHeaderDataFileName + ' '+ @sFileOutputPath+'\'+@sFileOutPutPrefix+@sCounter +@sFileExtension+' '
		--print @SQLforSQLCMD
		--exec xp_cmdshell @SQLforSQLCMD 



		--Copy dummy file to passed EXCEL file
		--set @SQLforSQLCMD= 'type '+@sFileOutputPath+'\'+@sDataHoldingFileName +@sFileExtension+' >> "'++ @sFileOutputPath+'\'+@sFileOutPutPrefix+@sCounter +@sFileExtension+' '
		--exec xp_cmdshell @SQLforSQLCMD 
		--print  @SQLforSQLCMD 

		SET @SQLforSQLCMD  = ''

		SET @iRemainingRows = @iRemainingRows - @iBatchSize  
		SET @iCounter = @iCounter + 1 
		SELECT @iRemainingRows,@iCounter,@iIterations


	END

	--set @SQLforSQLCMD= 'del /Q /F '+@sFileOutputPath+'\'+@sDataHoldingFileName +@sFileExtension
	--exec xp_cmdshell @SQLforSQLCMD 

	

UNABLETOPROCEED:
	print 'end of procedure'

END
GO


