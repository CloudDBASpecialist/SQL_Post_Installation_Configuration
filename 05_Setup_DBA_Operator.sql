﻿use [msdb]

GO
use [master]

GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'DBA_JOB_OPERATOR', 
		@enabled=1, 
		@pager_days=0, 
		@email_address=N'DB_TEAM@xyz.sa'
GO
