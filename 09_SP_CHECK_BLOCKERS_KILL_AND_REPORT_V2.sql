USE [DBA]
GO


/****** Object:  Table [dbo].[BLOCKED_SESSIONS_DETAILS]    Script Date: 1/30/2024 2:01:57 PM ******/
IF EXISTS (SELECT 1 from sys.objects where name ='BLOCKED_SESSIONS_DETAILS' and type = 'U')
BEGIN 
	DROP TABLE [DBA].[dbo].[BLOCKED_SESSIONS_DETAILS]
END
GO

/****** Object:  Table [dbo].[BLOCKED_SESSIONS_DETAILS]    Script Date: 1/30/2024 2:01:57 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[BLOCKED_SESSIONS_DETAILS](
	[PK_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[LOG_TIME] [datetime] NOT NULL,
	[ProcessType] [varchar](25) NULL,
	[Spid] [smallint] NULL,
	[blocked] [smallint] NULL,
	[DbName] [nvarchar](128) NULL,
	[hostname] [varchar](256) NULL,
	[program_name] [varchar](256) NULL,
	[cmd] [varchar](32) NULL,
	[loginame] [varchar](256) NULL,
	[last_batch] [datetime] NULL,
	[waitresource] [varchar](512) NULL,
	[waittime] [bigint] NULL,
	[waittype] [varchar](64) NULL,
	[text] [nvarchar](max) NULL,
	[done] [int] NULL,
	[killed_or_not] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[PK_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON,DATA_COMPRESSION=PAGE) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO





--select * FROM sys.sysprocesses A

USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[CHECK_BLOCKERS_KILL_AND_REPORT]    Script Date: 1/30/2024 9:55:26 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CHECK_BLOCKERS_KILL_AND_REPORT]
@AUTO_KILL BIT = 0,
@send_mail bit = 1,
@email_recipient_to varchar (500) = 'sos_db@elm.sa',
@email_recipient_cc varchar (1000) = NULL,
@subject varchar (100)= 'Blocking process report FROM SERVER ' ,
@stLoginNameToKillBlockingProcess1 varchar(100) = '%' , 
@stLoginNameToKillBlockingProcess2 varchar(100) = '' , 
@stLoginNameToKillBlockingProcess3 varchar(100) = '' , 
@stLoginNameToKillBlockingProcess4 varchar(100) = '' , 
@stProcessTypeToBeKilled varchar (100) = '%BLOCKER' ,
@stHostname1NotToKill1 varchar (100) = '%SQ%',
@stHostname1NotToKill2 varchar (100) = '%BI%',
@stHostname1NotToKill3 varchar (100) = '%TL%',
@stCmdNotToKill1 varchar (100) = '%UPDATE%',	
@stCmdNotToKill2 varchar (100) = '%INSERT%',	
@stCmdNotToKill3 varchar (100) = '%DELETE%',	
@iBlockingProcessThresholdToNotify int = 5 ,
@iBlockingProcessSecondsOldThresholdToNotify int = 120 ,
@iBlockingProcessSecondsOldToKill int = 90 --only the session older than 90 seconds will be killed or whatever number is given here
AS 
BEGIN 

	SET @subject = @subject + CAST(@@SERVERNAME AS VARCHAR)

	begin try
		drop table #blocked_sessions
		drop table ##mail_blocked_sessions 
	end try
	begin catch 
	end catch	

	SELECT distinct P.*,qt.text , 0 as done, 0 as killed_or_not

	into #blocked_sessions

	FROM 
	(
	SELECT CASE WHEN A.blocked = 0 then 'HEAD BLOCKER' ELSE 'BLOCKER' END AS ProcessType, A.spid Spid, A.blocked, DB_NAME(A.dbid) DbName, A.hostname, A.Sql_handle, A.program_name, A.cmd, A.loginame, A.last_batch, A.waitresource, A.waittime, A.lastwaittype waittype,A.cpu,	A.physical_io	,A.memusage
	FROM sys.sysprocesses A
	JOIN (SELECT DISTINCT Blocked, sql_handle FROM sys.sysprocesses WHERE blocked > 0) B
		  ON A.Spid = B.Blocked

	UNION ALL

	SELECT 'Blocked process' ProcessType, A.spid Spid, A.blocked, DB_NAME(A.dbid) DbName, A.hostname, A.Sql_handle, A.program_name, A.cmd, A.loginame, A.last_batch, A.waitresource, A.waittime, A.lastwaittype,A.cpu,	A.physical_io	,A.memusage
	FROM sys.sysprocesses A
	
	WHERE A.blocked > 0

	UNION ALL

	SELECT 'Ressource-waiting process' ProcessType, A.spid Spid, A.blocked, DB_NAME(A.dbid) DbName, A.hostname, A.Sql_handle, A.program_name, A.cmd, A.loginame, A.last_batch, A.waitresource, A.waittime, A.lastwaittype,A.cpu,	A.physical_io	,A.memusage
	FROM sys.sysprocesses A
	WHERE waittime >1000
	AND         lastwaittype not in ('waitfor','tracewrite')
	AND         program_name NOT LIKE 'DatabaseMail%'
	AND         sid <> 0x01
	) P
	cross apply sys.dm_exec_sql_text(P.sql_handle) as qt

	--SELECT * FROM #blocked_sessions

	if (select count (1) from DBA.dbo.BLOCKED_SESSIONS_DETAILS WITH (READPAST)  ) > 100000
	begin 
		DELETE TOP (1000) FROM DBA.dbo.BLOCKED_SESSIONS_DETAILS WHERE LOG_TIME < getdate ()-3
	end 

	declare @icount int , @iRowscount int , @ispid int , @idone int , @sql Nvarchar (max) , @stLoginName varchar(100)
	set @icount = 0
	SET @idone = -1

	--count the head blockers
	SELECT @iRowscount = COUNT(*) from #blocked_sessions where blocked = 0

	

	if @AUTO_KILL = 1 --and (select count(1) from #blocked_sessions )
	begin 
		select top 1 @ispid = spid  , @idone = done, @stLoginName = LTRIM(RTRIM(loginame)) from #blocked_sessions where blocked = 0 and done = 0 
		and ProcessType like @stProcessTypeToBeKilled --('HEAD BLOCKER' , 'BLOCKER') 
		and hostname not like @stHostname1NotToKill1 and hostname not like @stHostname1NotToKill2 and hostname not like @stHostname1NotToKill3 
		--and isnull(loginame,'%') like @stLoginNametoKillBlockingProcess 
		and datediff(second,last_batch,getdate()) > @iBlockingProcessSecondsOldToKill
		and cmd not like @stCmdNotToKill1
		and cmd not like @stCmdNotToKill2
		and cmd not like @stCmdNotToKill3
		order by last_batch asc

		while (@idone = 0)
		begin 

			set @sql = N'KILL ' + CAST (@ispid as Nvarchar ) --+ ')'
			--SET @sql = ' EXEC (KILL ' + CAST (@ispid as varchar ) + ')'
	
			SELECT @SQL
			if ( @stLoginName like @stLoginNameToKillBlockingProcess1 OR @stLoginName like @stLoginNameToKillBlockingProcess2
				OR @stLoginName like @stLoginNameToKillBlockingProcess3	OR @stLoginName like @stLoginNameToKillBlockingProcess4
			)
			begin
				exec sp_executesql @sql
			end
			SET @idone = 1 
			--update #blocked_sessions set done = 1 where Spid = @ispid
			update #blocked_sessions set done = 1,killed_or_not=1 where Spid = @ispid

			select top 1 @ispid = spid  , @idone = done, @stLoginName = LTRIM(RTRIM(loginame)) from #blocked_sessions where blocked = 0 and done = 0 
			and ProcessType like @stProcessTypeToBeKilled --('HEAD BLOCKER' , 'BLOCKER') 
			and hostname not like @stHostname1NotToKill1 and hostname not like @stHostname1NotToKill2 and hostname not like @stHostname1NotToKill3 
			--and isnull(loginame,'%') like @stLoginNametoKillBlockingProcess
			and datediff(second,last_batch,getdate()) > @iBlockingProcessSecondsOldToKill
			and cmd not like @stCmdNotToKill1
			and cmd not like @stCmdNotToKill2
			and cmd not like @stCmdNotToKill3
			order by last_batch asc

		end
	END 

	SELECT 
	getdate() AS LOG_TIME,ProcessType,Spid,blocked,DbName,hostname,program_name,cmd,loginame,last_batch,waitresource,waittime,waittype,killed_or_not,text as Query 
	into ##mail_blocked_sessions 
	from #blocked_sessions

	insert into DBA.dbo.BLOCKED_SESSIONS_DETAILS 
	(LOG_TIME,ProcessType,Spid,blocked,DbName,hostname,program_name,cmd,loginame,last_batch,waitresource,waittime,waittype,text,done,killed_or_not)
	
	select getdate() AS LOG_TIME,ProcessType,Spid,blocked,DbName,hostname,program_name,cmd,loginame,last_batch,waitresource,waittime,waittype,text,done,killed_or_not from #blocked_sessions

	IF (SELECT Count(1) FROM #blocked_sessions ) = 0 
	begin
		insert into DBA.dbo.BLOCKED_SESSIONS_DETAILS (LOG_TIME,ProcessType) select getdate(),'No Blocking Records'
	end
	IF (SELECT Count(1) FROM ##mail_blocked_sessions 
		where DATEDIFF (SECOND,last_batch,log_time) > @iBlockingProcessSecondsOldThresholdToNotify ) > @iBlockingProcessThresholdToNotify AND @send_mail = 1 
	BEGIN 

		begin try
			EXEC DBA.[dbo].[email_table]
			  @tablename  = '##mail_blocked_sessions'
			 ,@recipients = @email_recipient_to --'zaziz@elm.sa;aaalhuwaimel@elm.sa;aalmozaini@elm.sa'
			 ,@email_recipient_cc = @email_recipient_cc
			 ,@subject    = @subject 
		end try
		begin catch
			 EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBA', -- replace with your SQL Database Mail Profile 
			@body = 'MAIL FROM SERVER BLOCKERS JOB <BR>',
			@body_format ='HTML',
			@recipients = @email_recipient_to, -- replace with your email address
			@copy_recipients = @email_recipient_cc,
			@from_address = 'noreply@elm.sa',
			@subject = 'BLOCKING SESSIONS' ,
			@execute_query_database = 'msdb',
			@query = 'SELECT top 100 * FROM ##mail_blocked_sessions ';
		end catch

	END
END
GO


