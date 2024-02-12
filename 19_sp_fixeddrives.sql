USE master
IF OBJECT_ID('SP_GETOBJECTS') IS NOT NULL 
DROP PROCEDURE [dbo].sp_fixeddrives
GO 
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].sp_fixeddrives 
/*
Created By: Bandar
Version: 1.0
Date: 04-02-2023
*/

AS
BEGIN
EXEC sp_configure 'show advanced options', '1';
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', '1' ;
RECONFIGURE;

IF OBJECT_ID('tempdb..#diskspace') IS NOT NULL DROP TABLE #diskspace;
CREATE TABLE #diskspace ([output] [VARCHAR](500));


--Exec xp_cmdshell 'powershell.exe -Command { Get-WmiObject -Query "Select name,FileSystem,caption,capacity,freespace from Win32_Volume where FileSystem LIKE NTFS " }'
--xp_cmdshell 'PowerShell.exe -noprofile -command { Get-WmiObject -Query "Select name,FileSystem,caption,capacity,freespace from Win32_Volume where FileSystem LIKE ''NTFS'' " }'
insert into #diskspace([output])
--exec xp_cmdshell 'PowerShell.exe -noprofile -command "get-WmiObject Win32_volume |where {$_.name -Like ''*:*'' -and $_.Filesystem -eq ''NTFS''} |Format-Table -Property Name,{[int]($_.FreeSpace/1GB)},{[int]($_.Capacity/1GB)} -HideTableHeaders"'
exec xp_cmdshell 'PowerShell.exe -noprofile -command "get-WmiObject Win32_volume |where {$_.name -Like ''*:*'' -and $_.Filesystem -eq ''NTFS''} |Select-Object {$_.Name},{[int]($_.FreeSpace/1GB)},{[int]($_.Capacity/1GB)}| ConvertTo-Csv   -NoTypeInformation|Select-Object -Skip 1"';

delete from #diskspace  where [output] is null ;

  Select 
parsename(replace(replace([output],'"',''),',','.'), 3) Drive,
parsename(replace(replace([output],'"',''),',','.'), 2)  FreeGB,  
parsename(replace(replace([output],'"',''),',','.'), 1)   SizeGB
from #diskspace;

IF OBJECT_ID('tempdb..#diskspace') IS NOT NULL DROP TABLE #diskspace;

EXEC sp_configure 'xp_cmdshell', '0' ;
RECONFIGURE;
EXEC sp_configure 'show advanced options', '0';
RECONFIGURE;
END

go

sp_ms_marksystemobject 'sp_fixeddrives'

