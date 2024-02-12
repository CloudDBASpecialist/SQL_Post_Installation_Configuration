-- Create a Database Mail account

declare @serverComputerName nvarchar (255)
declare @account_name 		nvarchar (255)
declare @email_address 		nvarchar (255)
declare @replyto_address 	nvarchar (255)
declare @display_name    	nvarchar (255)
declare	@mailserver_name 	nvarchar (255)
declare @profile_name		nvarchar (255)



SELECT @serverComputerName = convert(varchar ,SERVERPROPERTY('ComputerNamePhysicalNetBIOS'))
  
SET	@account_name = 'DBA_MAIL_ACCOUNT'  
SET @email_address = @serverComputerName+'@elm.sa'    -- Change your domain name 
SET @replyto_address = 'noreply@elm.sa'
SET @display_name = @serverComputerName+' DBA Auto Mailer'  
SET @mailserver_name = '192.168.XX.XX'    -- your mail server IP
SET @profile_name = 'DBA_MAIL_PROFILE'
  
SELECT  @serverComputerName ,@account_name ,@email_address ,@replyto_address ,@display_name,@mailserver_name 	

 
  
EXECUTE msdb.dbo.sysmail_add_account_sp  
    @account_name = 'DBA_MAIL_ACCOUNT',  
    @description = 'Mail account for Database Server e-mail.',  
    @email_address = @email_address,  
    @replyto_address = @replyto_address,  
    @display_name = @display_name,  
    @mailserver_name = @mailserver_name ;  
  
-- Create a Database Mail profile  
EXECUTE msdb.dbo.sysmail_add_profile_sp  
    @profile_name = @profile_name,  
    @description = 'Profile used for Database Server mail.' ;  
  
-- Add the account to the profile  
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp  
    @profile_name = @profile_name,  
    @account_name = @account_name,  
    @sequence_number =1 ;  
  
-- Grant access to the profile to the DBMailUsers role  
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp  
    @profile_name = @profile_name,  
    @principal_name = 'guest',  
    @is_default = 1 ;  