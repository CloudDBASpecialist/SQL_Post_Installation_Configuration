
/****** 1. Schedule Job [DBA_Monitoring_Check_Blocking_Processes_every3Minutes] ******/

USE [msdb]
GO

/****** Object:  Job [DBA_Monitoring_Check_Blocking_Processes_every3Minutes]    Script Date: 11/02/2024 5:38:05 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Monitoring]    Script Date: 11/02/2024 5:38:05 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Monitoring' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Monitoring'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA_Monitoring_Check_Blocking_Processes_every3Minutes', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Monitoring', 
		 @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [capture data]    Script Date: 11/02/2024 5:38:05 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'capture data', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [DBA]
GO

DECLARE @RC int
DECLARE @AUTO_KILL bit
DECLARE @send_mail bit
DECLARE @email_recipient_to varchar(500)
DECLARE @email_recipient_cc varchar(1000)
DECLARE @subject varchar(100)
DECLARE @stLoginNameToKillBlockingProcess1 varchar(100)
DECLARE @stLoginNameToKillBlockingProcess2 varchar(100)
DECLARE @stLoginNameToKillBlockingProcess3 varchar(100)
DECLARE @stLoginNameToKillBlockingProcess4 varchar(100)
DECLARE @stProcessTypeToBeKilled varchar(100)
DECLARE @stHostname1NotToKill1 varchar(100)
DECLARE @stHostname1NotToKill2 varchar(100)
DECLARE @stHostname1NotToKill3 varchar(100)
DECLARE @stCmdNotToKill1 varchar(100)
DECLARE @stCmdNotToKill2 varchar(100)
DECLARE @stCmdNotToKill3 varchar(100)
DECLARE @iBlockingProcessThresholdToNotify int
DECLARE @iBlockingProcessSecondsOldThresholdToNotify int
DECLARE @iBlockingProcessSecondsOldToKill int

SET @AUTO_KILL										=0
SET @send_mail										=1
SET @email_recipient_to								=''sos_db@elm.sa''
SET @email_recipient_cc								=''''
SET @subject										=''Blocking process report FROM SERVER ''
SET @stLoginNameToKillBlockingProcess1				= ''%''
SET @stLoginNameToKillBlockingProcess2				= '''' 
SET @stLoginNameToKillBlockingProcess3				= '''' 
SET @stLoginNameToKillBlockingProcess4				= '''' 
SET @stProcessTypeToBeKilled						=''%BLOCKER''
SET @stHostname1NotToKill1							=''%SQ%''
SET @stHostname1NotToKill2							=''%BI%''
SET @stHostname1NotToKill3							=''%TL%''
SET @stCmdNotToKill1								=''%UPDATE%''
SET @stCmdNotToKill2								=''%INSERT%''
SET @stCmdNotToKill3								=''%DELETE%''
SET @iBlockingProcessThresholdToNotify				=5
SET @iBlockingProcessSecondsOldThresholdToNotify	=120
SET @iBlockingProcessSecondsOldToKill				=90

EXECUTE @RC = [dbo].[CHECK_BLOCKERS_KILL_AND_REPORT] 
   @AUTO_KILL
  ,@send_mail
  ,@email_recipient_to
  ,@email_recipient_cc
  ,@subject
  ,@stLoginNameToKillBlockingProcess1
  ,@stLoginNameToKillBlockingProcess2
  ,@stLoginNameToKillBlockingProcess3
  ,@stLoginNameToKillBlockingProcess4
  ,@stProcessTypeToBeKilled
  ,@stHostname1NotToKill1
  ,@stHostname1NotToKill2
  ,@stHostname1NotToKill3
  ,@stCmdNotToKill1
  ,@stCmdNotToKill2
  ,@stCmdNotToKill3
  ,@iBlockingProcessThresholdToNotify
  ,@iBlockingProcessSecondsOldThresholdToNotify
  ,@iBlockingProcessSecondsOldToKill
GO

', 
		@database_name=N'DBA', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'every 3 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=3, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20201111, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'6836a88d-c8a1-4143-bc7e-58c13a0decaa'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO






USE [msdb]
GO

/****** 2 :  Job [DBA_Monitoring_Check_DB_Status_every10Minutes]     ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Monitoring]    Script Date: 11/02/2024 5:53:06 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Monitoring' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Monitoring'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA_Monitoring_Check_DB_Status_every10Minutes', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@category_name=N'Database Monitoring', 
				@notify_email_operator_name=N'DBA_JOB_OPERATOR', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Database Status]    Script Date: 11/02/2024 5:53:06 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Database Status', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
declare @ErrorMsg varchar (1500)
declare @databases_not_online varchar(1000)
SET @databases_not_online = ''''

if (select count (1) from sys.databases where name not like ''%test%'' and state <> 0) > 0 
begin 
	select @databases_not_online = @databases_not_online + name + 
	CASE 
		WHEN state = 0 then '' ONLINE'' 
		WHEN state = 1 then '' RESTORING'' 
		WHEN state = 2 then '' RECOVERING''
		WHEN state = 3 then '' RECOVERY_PENDING''
		WHEN state = 4 then '' SUSPECT''
		WHEN state = 5 then '' EMERGENCY''
		WHEN state = 6 then '' OFFLINE''
		WHEN state = 7 then '' COPYING - SQL AZURE''
		WHEN state = 10 then '' OFFLINE SECONDARY''
	ELSE '' UNKNOWN STATUS '' + CAST (state as varchar) END 
	+ '', '' from sys.databases where name not like ''%test%'' and state <> 0

	select SUBSTRING(@databases_not_online, 0, LEN(@databases_not_online))
	SET @ErrorMsg =  ''HIGH Alert : Database not online --> '' + @databases_not_online 
	SELECT @ErrorMsg
	RAISERROR ( @ErrorMsg , 16 , 1 ) WITH LOG ;
	
end 


', 
		@database_name=N'master', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'every10Minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20210211, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'3a46b023-91b5-419d-b996-9cfa77dd0d18'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO





USE [msdb]
GO

/****** 3 :  Job [DBA_Monitoring_Number_of_Blocked_Sessions_every5minutes]    Script Date: 11/02/2024 5:54:04 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Monitoring]    Script Date: 11/02/2024 5:54:04 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Monitoring' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Monitoring'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA_Monitoring_Number_of_Blocked_Sessions_every5minutes', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@category_name=N'Database Monitoring', 
		 @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check_Number_Sessions_Which_are_Blocked]    Script Date: 11/02/2024 5:54:04 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check_Number_Sessions_Which_are_Blocked', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @NumberOfBlockedSessions int 
declare @ErrorMsg varchar (1500)

select @NumberOfBlockedSessions = count(distinct spid) From sys.sysprocesses where blocked <> 0  
select @NumberOfBlockedSessions 

SELECT @ErrorMsg = 
	CASE 
WHEN @NumberOfBlockedSessions > 50 and @NumberOfBlockedSessions < 100		then ''LOW : Blocking Session more than 50 less than 100''
WHEN @NumberOfBlockedSessions >= 100 and @NumberOfBlockedSessions < 500		then ''MEDIUM : Blocking Session more than 100 less than 500''
WHEN @NumberOfBlockedSessions >= 500 and @NumberOfBlockedSessions < 1000	then ''HIGH : Blocking Session more than 500 less than 1000''
WHEN @NumberOfBlockedSessions >= 1000 then ''CRITICAL : Blocking Session more than 1000''
else '' '' END 

SELECT @ErrorMsg

if @NumberOfBlockedSessions  > 50 
begin 

	RAISERROR ( @ErrorMsg , 16 , 1 ) WITH LOG ;
	
end 
', 
		@database_name=N'master', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'every5Minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20210211, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'56048e50-30a8-488e-9601-ed89c5dc82a7'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


