USE [msdb]
GO

--SET USER Database integrity job schedule
declare @job_id nvarchar (100)
select @job_id = job_id From msdb.dbo.sysjobs where name = 'DatabaseIntegrityCheck - USER_DATABASES'

DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_id=@job_id, @name=N'weekly', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=32, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210211, 
		@active_end_date=99991231, 
		@active_start_time=60000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id

EXEC msdb.dbo.sp_update_jobstep @job_id=@job_id, @step_id=1 , 
		@command=N'EXECUTE [dbo].[DatabaseIntegrityCheck]
@Databases = ''USER_DATABASES'',
@LogToTable = ''Y'',
@PhysicalOnly = ''Y'',
@TabLock = ''Y'''

GO



--SET LOG Backup job schedule
declare @job_id nvarchar (100)
select @job_id = job_id From msdb.dbo.sysjobs where name = 'DatabaseBackup - USER_DATABASES - LOG'

EXEC msdb.dbo.sp_update_jobstep @job_id=@job_id, @step_id=1 , 
		@command=N'EXECUTE [dbo].[DatabaseBackup]
@Databases = ''USER_DATABASES'',
@Directory = ''B:\DB_BACKUP'',
@BackupType = ''LOG'',
@Verify = ''Y'',
@CleanupTime = 72,
@CheckSum = ''Y'',
@LogToTable = ''Y''', 
		@flags=4

DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_id=@job_id, @name=N'every 5 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210211, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO




USE [msdb]
GO
--SET CommandLog Cleanup job schedule
declare @job_id nvarchar (100)
select @job_id = job_id From msdb.dbo.sysjobs where name = 'CommandLog Cleanup'

DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_id=@job_id, @name=N'nightly 0100', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210211, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO




USE [msdb]
GO

--SET DatabaseIntegrityCheck - SYSTEM_DATABASES job schedule
declare @job_id nvarchar (100)
select @job_id = job_id From msdb.dbo.sysjobs where name = 'DatabaseIntegrityCheck - SYSTEM_DATABASES'


DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_id=@job_id, @name=N'monthly', 
		@enabled=1, 
		@freq_type=16, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210211, 
		@active_end_date=99991231, 
		@active_start_time=70000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO


use msdb
go

--SET IndexOptimize job schedule
declare @job_id nvarchar (100)
select @job_id = job_id From msdb.dbo.sysjobs where name = 'IndexOptimize - USER_DATABASES'


EXEC msdb.dbo.sp_update_jobstep @job_id=@job_id, @step_id=1 , 
		@command=N'EXECUTE [dbo].[IndexOptimize]
@Databases = ''USER_DATABASES'',
@SortInTempDb = ''Y'',
@LogToTable = ''Y'',
@FragmentationMedium = ''INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
@FragmentationHigh = ''INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,
@UpdateStatistics = ''ALL''', 
		@flags=4


DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_id=@job_id, @name=N'daily 2 AM', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210211, 
		@active_end_date=99991231, 
		@active_start_time=20000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO

