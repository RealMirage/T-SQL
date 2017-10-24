--System Stored proc to set the Default DB upon connecting to OLEDB query on SQL Server.
EXEC sp_defaultdb @loginame='domain\user', @defdb='DesiredDefaultDB' 