/*

"Ensure 'SQL Server Audit' is set to capture both 'failed' and
'successful logins' (Automated)"

SELECT
S.name AS 'Audit Name'
, CASE S.is_state_enabled
WHEN 1 THEN 'Y'
WHEN 0 THEN 'N' END AS 'Audit Enabled'
, S.type_desc AS 'Write Location'
, SA.name AS 'Audit Specification Name'
, CASE SA.is_state_enabled
WHEN 1 THEN 'Y'
WHEN 0 THEN 'N' END AS 'Audit Specification Enabled'
, SAD.audit_action_name
, SAD.audited_result
FROM sys.server_audit_specification_details AS SAD
JOIN sys.server_audit_specifications AS SA
ON SAD.server_specification_id = SA.server_specification_id
JOIN sys.server_audits AS S
ON SA.audit_guid = S.audit_guid
WHERE SAD.audit_action_id IN ('CNAU', 'LGFL', 'LGSD');

The result set should contain 3 rows, one for each of the following audit_action_names:

• AUDIT_CHANGE_GROUP
• FAILED_LOGIN_GROUP
• SUCCESSFUL_LOGIN_GROUP
Both the Audit and Audit specification should be enabled and the audited_result should 
include both success and failure.
*/
USE master
GO

-- Check if the server audit 'TrackLogins' already exists
IF NOT EXISTS (SELECT * FROM sys.server_audits WHERE name = 'TrackLogins')
BEGIN
    CREATE SERVER AUDIT TrackLogins
    TO APPLICATION_LOG;
END
GO

-- Check if the server audit specification 'TrackAllLogins' already exists
IF NOT EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = 'TrackAllLogins')
BEGIN
    CREATE SERVER AUDIT SPECIFICATION TrackAllLogins
    FOR SERVER AUDIT TrackLogins
    ADD (FAILED_LOGIN_GROUP),
    ADD (SUCCESSFUL_LOGIN_GROUP),
    ADD (AUDIT_CHANGE_GROUP)
    WITH (STATE = ON);
END
GO

-- Enable the server audit if it exists
IF EXISTS (SELECT * FROM sys.server_audits WHERE name = 'TrackLogins')
BEGIN
    ALTER SERVER AUDIT TrackLogins
    WITH (STATE = ON);
END
GO

/*
disable xp_cmdshell

"Verify that the 'xp_cmdshell' option to disabled.  
The xp_cmdshell procedure allows an authenticated SQL Server user to execute operating-system command shell commands and return results as rows within the SQL client."

*/

GO

EXECUTE sp_configure 'show advanced options',1; RECONFIGURE WITH OVERRIDE; 
EXECUTE sp_configure 'xp_cmdshell' , 0 ;
EXECUTE sp_configure 'show advanced options',0; RECONFIGURE WITH OVERRIDE; 

GO

/*
"Ensure 'CLR Assembly Permission Set' is set to 'SAFE_ACCESS' for All
CLR Assemblies (Automated)"

Cannot be done automatically

SELECT name,
permission_set_desc
FROM sys.assemblies
WHERE is_user_defined = 1;
All the returned assemblies should show SAFE_ACCESS in the permission_set_desc
column.

ALTER ASSEMBLY <assembly_name> WITH PERMISSION_SET = SAFE;


*/




GO 

declare @sql_fix_assembly_permissions nvarchar (4000)
SET @sql_fix_assembly_permissions= ' ' 

SELECT @sql_fix_assembly_permissions = @sql_fix_assembly_permissions + 'ALTER ASSEMBLY ' +name +' WITH PERMISSION_SET = SAFE;' + NCHAR(13) + NCHAR(10)
FROM sys.assemblies
WHERE is_user_defined = 1 and permission_set_desc <> 'SAFE_ACCESS'


select @sql_fix_assembly_permissions = SUBSTRING(@sql_fix_assembly_permissions, 0, LEN(@sql_fix_assembly_permissions))
select @sql_fix_assembly_permissions
exec sp_executesql @sql_fix_assembly_permissions


GO


/*

Ensure 'Default Trace Enabled' Server Configuration Option is set to '1' (Automated)

*/
GO

--Run the following T-SQL command:
SELECT name,
CAST(value as int) as value_configured,
CAST(value_in_use as int) as value_in_use
FROM sys.configurations
WHERE name = 'default trace enabled';

--Both value columns must show 1."	"Run the following T-SQL command:
EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;
EXECUTE sp_configure 'default trace enabled', 1;
RECONFIGURE;
GO
EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;

GO

/*
"Ensure 'CHECK_POLICY' Option is set to 'ON' for All SQL
Authenticated Logins (Automated)"
*/

GO

declare @sql_fix_logins nvarchar (4000)
SET @sql_fix_logins = ' ' 

SELECT @sql_fix_logins = @sql_fix_logins + 'ALTER LOGIN [' +name +'] WITH CHECK_POLICY = ON;' + NCHAR(13) + NCHAR(10)
FROM sys.sql_logins
WHERE is_policy_checked = 0;


--select * FROM sys.sql_logins WHERE is_policy_checked = 0;


select @sql_fix_logins = SUBSTRING(@sql_fix_logins , 0, LEN(@sql_fix_logins ))
select @sql_fix_logins
exec sp_executesql @sql_fix_logins 


GO



/*

CANNOT be done automatically because many users are sql logins and are application users

Ensure 'CHECK_EXPIRATION' Option is set to 'ON' for All SQL Authenticated Logins Within the Sysadmin Role (Automated)								Yes	Security	"Run the following T-SQL statement to find sysadmin or equivalent logins with 
CHECK_EXPIRATION = OFF. No rows should be returned.
SELECT l.[name], 'sysadmin membership' AS 'Access_Method'
FROM sys.sql_logins AS l
WHERE IS_SRVROLEMEMBER('sysadmin',name) = 1
AND l.is_expiration_checked <> 1
UNION ALL
SELECT l.[name], 'CONTROL SERVER' AS 'Access_Method'
FROM sys.sql_logins AS l
JOIN sys.server_permissions AS p
ON l.principal_id = p.grantee_principal_id
WHERE p.type = 'CL' AND p.state IN ('G', 'W')
AND l.is_expiration_checked <> 1;
For each <login_name> found by the Audit Procedure, execute the following T-SQL 
statement:
ALTER LOGIN [<login_name>] WITH CHECK_EXPIRATION = ON;

*/	




/*

"Ensure 'MUST_CHANGE' Option is set to 'ON' for All SQL
Authenticated Logins (Manual)"								Yes	Security	"1. Open SQL Server Management Studio.
2. Open Object Explorer and connect to the target instance.
3. Navigate to the Logins tab in Object Explorer and expand. Right click on the 
desired login and select Properties.
4. Verify the User must change password at next login checkbox is checked.
Note: This audit procedure is only applicable immediately after the login has been created 
or altered to force the password change. Once the password is changed, there is no way to 
know specifically that this option was the forcing mechanism behind a password change."	"Set the MUST_CHANGE option for SQL Authenticated logins when creating a login initially:
CREATE LOGIN <login_name> WITH PASSWORD = '<password_value>' MUST_CHANGE,
CHECK_EXPIRATION = ON, CHECK_POLICY = ON;
Set the MUST_CHANGE option for SQL Authenticated logins when resetting a password:
ALTER LOGIN <login_name> WITH PASSWORD = '<new_password_value>' MUST_CHANGE;"

*/


GO

/*

"Ensure the public role in the msdb database is not granted access
to SQL Agent proxies (Automated)"								Yes	Security	"Use the following syntax to determine if access to any proxies have been granted to the 
msdb database's public role.
USE [msdb]
GO
SELECT sp.name AS proxyname
FROM dbo.sysproxylogin spl
JOIN sys.database_principals dp
ON dp.sid = spl.sid
JOIN sysproxies sp
ON sp.proxy_id = spl.proxy_id
WHERE principal_id = USER_ID('public');
GO
This query should not return any rows.
"	"1. Ensure the required security principals are explicitly granted access to the proxy 
(use sp_grant_login_to_proxy).
2. Revoke access to the <proxyname> from the public role.
USE [msdb]
GO
EXEC dbo.sp_revoke_login_from_proxy @name = N'public', @proxy_name =
N'<proxyname>';
GO
"


*/






/*


Ensure Windows local groups are not SQL Logins (Automated)


"Use the following syntax to determine if any local groups have been added as SQL Server 
Logins.
USE [master]
GO
SELECT pr.[name] AS LocalGroupName, pe.[permission_name], pe.[state_desc]
FROM sys.server_principals pr
JOIN sys.server_permissions pe
ON pr.[principal_id] = pe.[grantee_principal_id]
WHERE pr.[type_desc] = 'WINDOWS_GROUP'
AND pr.[name] like CAST(SERVERPROPERTY('MachineName') AS nvarchar) + '%';
This query should not return any rows."

*/






/*

Ensure Windows BUILTIN groups are not SQL Logins (Automated)								Yes	Security	"Use the following syntax to determine if any BUILTIN groups or accounts have been added 
as SQL Server Logins.
SELECT pr.[name], pe.[permission_name], pe.[state_desc]
FROM sys.server_principals pr
JOIN sys.server_permissions pe
ON pr.principal_id = pe.grantee_principal_id
WHERE pr.name like 'BUILTIN%';
This query should not return any rows.
"	"1. For each BUILTIN login, if needed create a more restrictive AD group containing only 
the required user accounts.
2. Add the AD group or individual Windows accounts as a SQL Server login and grant it 
the permissions required.
3. Drop the BUILTIN login using the syntax below after replacing <name> in 
[BUILTIN\<name>].
USE [master]
GO
DROP LOGIN [BUILTIN\<name>]
GO"


*/


/*
Cannot be automated


Ensure only the default permissions specified by Microsoft are granted to the public server role (Automated)


"Use the following syntax to determine if extra permissions have been granted to the public
server role.
SELECT *
FROM master.sys.server_permissions
WHERE (grantee_principal_id = SUSER_SID(N'public') and state_desc LIKE
'GRANT%')
AND NOT (state_desc = 'GRANT' and [permission_name] = 'VIEW ANY DATABASE' and
class_desc = 'SERVER')
AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and
class_desc = 'ENDPOINT' and major_id = 2)
AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and
class_desc = 'ENDPOINT' and major_id = 3)
AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and
class_desc = 'ENDPOINT' and major_id = 4)
AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and
class_desc = 'ENDPOINT' and major_id = 5);
This query should not return any rows.
"	"1. Add the extraneous permissions found in the Audit query results to the specific 
logins to user-defined server roles which require the access.
2. Revoke the <permission_name> from the public role as shown below
USE [master]
GO
REVOKE <permission_name> FROM public;
GO"



*/



/*

Cannot be done automatically as no cases found

"Ensure CONNECT permissions on the 'guest' user is Revoked within
all SQL Server databases excluding the master, msdb and tempdb
(Automated)"								Yes	Security	"Run the following code snippet for each database (replacing <database_name> as 
appropriate) in the instance to determine if the guest user has CONNECT permission. No 
rows should be returned.
USE <database_name>;
GO
SELECT DB_NAME() AS DatabaseName, 'guest' AS Database_User,
[permission_name], [state_desc]
FROM sys.database_permissions
WHERE [grantee_principal_id] = DATABASE_PRINCIPAL_ID('guest')
AND [state_desc] LIKE 'GRANT%'
AND [permission_name] = 'CONNECT'
AND DB_NAME() NOT IN ('master','tempdb','msdb');	

"The following code snippet revokes CONNECT permissions from the guest user in a 
database. Replace <database_name> as appropriate:

USE <database_name>;
GO
REVOKE CONNECT FROM guest;"


*/






/*

"SELECT name
FROM sys.databases
WHERE is_trustworthy_on = 1
AND name != 'msdb';
No rows should be returned."	"Execute the following T-SQL statement against the databases (replace <database_name>
below) returned by the Audit Procedure:
ALTER DATABASE [<database_name>] SET TRUSTWORTHY OFF;"

*/
GO

declare @sql_fix_trustworthy nvarchar (4000)
SET @sql_fix_trustworthy = ' ' 

SELECT @sql_fix_trustworthy= @sql_fix_trustworthy+ 'ALTER DATABASE [' +name +'] SET TRUSTWORTHY OFF;' + NCHAR(13) + NCHAR(10)
FROM sys.databases
WHERE is_trustworthy_on = 1 AND name != 'msdb';


--select * FROM sys.sql_logins WHERE is_policy_checked = 0;


select @sql_fix_trustworthy = SUBSTRING(@sql_fix_trustworthy, 0, LEN(@sql_fix_trustworthy))
select @sql_fix_trustworthy
exec sp_executesql @sql_fix_trustworthy


GO


/*

Ensure 'Scan For Startup Procs' Server Configuration Option is set to '0' (Automated)		
"SELECT name,
CAST(value as int) as value_configured,
CAST(value_in_use as int) as value_in_use
FROM sys.configurations
WHERE name = 'scan for startup procs';
Both value columns must show 0."	"

EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;
EXECUTE sp_configure 'scan for startup procs', 0;
RECONFIGURE;
GO
EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;
Restart the Database Engine.

"


*/

GO

EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;
EXECUTE sp_configure 'scan for startup procs', 0;
RECONFIGURE;
GO
EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;


--Restart the Database Engine.


GO


/*

CANNOT BE AUTOMATED AS SOME SERVERS MAY BE USING THIS OPTION

Ensure 'Remote Access' Server Configuration Option is set to '0'								Yes	Security	"SELECT name,
CAST(value as int) as value_configured,
CAST(value_in_use as int) as value_in_use
FROM sys.configurations
WHERE name = 'remote access';
Both value columns must show 0.
"	"EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;
EXECUTE sp_configure 'remote access', 0;
RECONFIGURE;
GO
EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;
"


*/







/*

Ensure 'Ole Automation Procedures' Server Configuration Option is
set to '0' (Automated)
In case server is being monitored by IDERA then enable it as IDERA will capture server performance
Run the following T-SQL command:
SELECT name,
CAST(value as int) as value_configured,
CAST(value_in_use as int) as value_in_use
FROM sys.configurations
WHERE name = 'Ole Automation Procedures';
Both value columns must show 0 to be compliant.
"	"EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;
EXECUTE sp_configure 'Ole Automation Procedures', 0;
RECONFIGURE;
GO
EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;


*/


GO

EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;
EXECUTE sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
GO
EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;


GO


/*

"Ensure 'Cross DB Ownership Chaining' Server Configuration Option is
set to '0' (Automated)"								Yes	Security	"SELECT name,
CAST(value as int) as value_configured,
CAST(value_in_use as int) as value_in_use
FROM sys.configurations
WHERE name = 'cross db ownership chaining';
Both value columns must show 0 to be compliant.
"	"EXECUTE sp_configure 'cross db ownership chaining', 0;
RECONFIGURE;
GO
"


*/

GO

EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXECUTE sp_configure 'cross db ownership chaining', 0;
RECONFIGURE;
GO
GO
EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;


GO




/*

"Enabling use of CLR assemblies widens the attack surface of SQL Server and puts it at risk 
from both inadvertent and malicious assemblies.
If CLR assemblies are in use, applications may need to be rearchitected to eliminate their 
usage before disabling this setting. Alternatively, some organizations may allow this setting 
to be enabled 1 for assemblies created with the SAFE permission set, but disallow 
assemblies created with the riskier UNSAFE and EXTERNAL_ACCESS permission sets. To find 
user-created assemblies, run the following query in all databases, replacing 
<database_name> with each database name:
16 | P a g e
USE [<database_name>]
GO
SELECT name AS Assembly_Name, permission_set_desc
FROM sys.assemblies
WHERE is_user_defined = 1;
GO
Default Value:
By default, this option is disabled (0)."								Yes	Surface Area Reduction	"SELECT name,
CAST(value as int) as value_configured,
CAST(value_in_use as int) as value_in_use
FROM sys.configurations
WHERE name = 'clr enabled';"	"EXECUTE sp_configure 'clr enabled', 0;
RECONFIGURE;
"

*/


GO
EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;

GO

EXECUTE sp_configure 'clr enabled', 0;
RECONFIGURE;
GO
EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;

GO



/*
"Ensure 'Ad Hoc Distributed Queries' Server Configuration Option is
set to '0' (Automated)"			Yes	Yes	Yes	Yes	Yes	Yes	Surface Area Reduction	"SELECT name, CAST(value as int) as value_configured, CAST(value_in_use as
int) as value_in_use
FROM sys.configurations
WHERE name = 'Ad Hoc Distributed Queries';"	"Remediation:
Run the following T-SQL command:
EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;
EXECUTE sp_configure 'Ad Hoc Distributed Queries', 0;
RECONFIGURE;
GO
EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;"

EXECUTE sp_configure 'Ad Hoc Distributed Queries'

*/


GO

EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;
EXECUTE sp_configure 'Ad Hoc Distributed Queries', 0;
RECONFIGURE;
GO
EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;


GO






/*


SELECT o.[name] AS [SPName]

,u.[name] AS [Role]

FROM [master]..[sysobjects] o

INNER JOIN [master]..[sysprotects] p

ON o.[id] = p.[id]

INNER JOIN [master]..[sysusers] u

ON P.Uid = U.UID

AND p.[uid] = 0

AND o.[xtype] IN ('X','P')


*/


/*

RENAME SA Account 

"Use the following syntax to determine if the sa account is disabled. Checking for sid=0x01
ensures that the original sa account is being checked in case it has been renamed per best 
practices.
SELECT name, is_disabled
FROM sys.server_principals
WHERE sid = 0x01
AND is_disabled = 0;
No rows should be returned to be compliant.
An is_disabled value of 0 indicates the login is currently enabled and therefore needs 
remediation.
SELECT name
FROM sys.server_principals
WHERE sid = 0x01 ;
A name of sa indicates the account has not been renamed and therefore needs remediation."	"Execute the following T-SQL query:
USE [master]
GO
DECLARE @tsql nvarchar(max)
SET @tsql = 'ALTER LOGIN ' + SUSER_NAME(0x01) + ' DISABLE'
EXEC (@tsql)
GO
Replace the <different_user> value within the below syntax and execute to rename the sa
login.
ALTER LOGIN sa WITH NAME = <different_user>;
"
*/

--declare @serverhostname nvarchar (50)
--SELECT @serverhostname = @@SERVERNAME

--declare @serviceNickName nvarchar (5)
--SET @serviceNickName = SUBSTRING(@serverhostname,5,3)
--SELECT @serviceNickName

--declare @newSA nvarchar (10)
--SET @newSA = 'sa-'+@serviceNickName
--SELECT @newSA 

--if exists (
--SELECT name
--FROM sys.server_principals
--WHERE sid = 0x01 )
--begin 
	
--	DECLARE @tsql nvarchar(max)
--	SET @tsql = 'ALTER LOGIN ' + SUSER_NAME(0x01) + ' DISABLE'
--	EXEC (@tsql)
	
--	SET @tsql = 'ALTER LOGIN sa WITH NAME = [' + @newSA+']'
--	EXEC (@tsql)
--end	

	
--GO

/*

Create DBA Team Users

*/


/*

"Following Server level settings should be done: 
Compress Backup should be checked in database settings
Login Audit for both Failed and Successful Logins
Server Authentication to be windows only. In case there are any applications not support windows authentication then Mixed mode authentication can be used"	  	Yes		Yes	Yes	Yes	Yes	Yes	Database Setup	"EXEC xp_loginconfig 'audit level';
A config_value of failure indicates a server login auditing setting of Failed logins only. 
If a config_value of all appears, then both failed and successful logins are being logged. 
Both settings should also be considered valid, but as mentioned capturing successful logins 
using this method creates lots of noise in the SQL Server Errorlog."	"Perform either the GUI or T-SQL method shown:
GUI Method
1. Open SQL Server Management Studio.
2. Right click the target instance and select Properties and navigate to the Security
tab.
3. Select the option Failed logins only under the Login Auditing section and click OK.
4. Restart the SQL Server instance.
T-SQL Method
1. Run:
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE',
N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel',
REG_DWORD, 3 -- 3 is for all
2. Restart the SQL Server instance."


*/

GO


EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel',REG_DWORD, 3 


GO

/*
"Configure SQL Server Error Logs to retain a maximum of 90 files
Configure SQL Agent Error Log to contain maximum of 10000 rows and maximum of 1000 rows per job history to be cleared after 4 weeks.
Schedule a nightly job to recycle server error log at 0000 hrs"	Yes					Yes			Database Setup	"Perform either the GUI or T-SQL method shown:
GUI Method
1. Open SQL Server Management Studio.
2. Open Object Explorer and connect to the target instance.
3. Navigate to the Management tab in Object Explorer and expand. Right click on the 
SQL Server Logs file and select Configure.
4. Verify the Limit the number of error log files before they are recycled checkbox 
is checked
5. Verify the Maximum number of error log files is greater than or equal to 90
T-SQL Method
Run the following T-SQL. The NumberOfLogFiles returned should be greater than or equal 
to 90.
DECLARE @NumErrorLogs int;
EXEC master.sys.xp_instance_regread
N'HKEY_LOCAL_MACHINE',
N'Software\Microsoft\MSSQLServer\MSSQLServer',
N'NumErrorLogs',
@NumErrorLogs OUTPUT;
SELECT ISNULL(@NumErrorLogs, -1) AS [NumberOfLogFiles];"	"Adjust the number of logs to prevent data loss. The default value of 6 may be insufficient for 
a production environment. Perform either the GUI or T-SQL method shown:
GUI Method
1. Open SQL Server Management Studio.
2. Open Object Explorer and connect to the target instance.
3. Navigate to the Management tab in Object Explorer and expand. Right click on the 
SQL Server Logs file and select Configure
4. Check the Limit the number of error log files before they are recycled
5. Set the Maximum number of error log files to greater than or equal to 90
T-SQL Method
Run the following T-SQL to change the number of error log files, replace <NumberAbove12>
with your desired number of error log files:
EXEC master.sys.xp_instance_regwrite
N'HKEY_LOCAL_MACHINE',
N'Software\Microsoft\MSSQLServer\MSSQLServer',
N'NumErrorLogs',
REG_DWORD,
<NumberAbove12>;
"

*/
USE [Master]
GO

EXEC master.sys.xp_instance_regwrite N'HKEY_LOCAL_MACHINE',  
N'Software\Microsoft\MSSQLServer\MSSQLServer', 
N'NumErrorLogs', 
REG_DWORD, 
60;
GO

/*
Default database backup to be Compressed backup
*/


EXEC sys.sp_configure N'backup compression default', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO

/*
SQL SERVER AGENT history logs
*/

USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @errorlogging_level=7
GO
declare @dtOldestDate datetime 
SET @dtOldestDate = GETDATE () -91 
EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date=@dtOldestDate 
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=100000, 
		@jobhistory_max_rows_per_job=10000, 
		@errorlogging_level=7
GO


/*
Setting max memory to 80 percent of total memory , if more is desired do it manually



declare @totalphysical_memory_mb int 
SELECT @totalphysical_memory_mb  = physical_memory_kb/1024 FROM sys.dm_os_sys_info

declare @suggestedmemory int 

SET @suggestedmemory = @totalphysical_memory_mb * 0.80
SELECT @suggestedmemory
 

EXEC sp_configure 'show advanced option', '1'
RECONFIGURE
EXEC sp_configure 'max server memory (MB)', @suggestedmemory
RECONFIGURE
EXEC sp_configure 'show advanced option', '0'
RECONFIGURE
GO
*/

/* SET MAX DEGREE OF PARALLELISM TO BE 8 */


EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO

declare @cpu_count int
select @cpu_count = max(cpu_count)  from sys.dm_os_nodes

EXEC sys.sp_configure N'max degree of parallelism', @cpu_count
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
GO




/*SET COST OF PARALLELISM to 16*/

--EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
--GO
--EXEC sys.sp_configure N'cost threshold for parallelism', N'16'
--GO
--RECONFIGURE WITH OVERRIDE
--GO
--EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
--GO





/*Model Database Settings*/

use [model]

GO
use [master]

GO
USE [master]
GO
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modeldev', FILEGROWTH = 131072KB )
GO
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modellog', FILEGROWTH = 65536KB )
GO

/*Enable Remote admin connections */

 EXEC sp_configure 'remote admin connections', 1;
 GO
 RECONFIGURE
 GO



-- Enable mixed mode authentication
USE master;
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;
GO


--Enable the DAC
sp_configure 'remote admin connections', 1;
RECONFIGURE;


