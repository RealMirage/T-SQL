--One line for renaming a column in a table specifically.
--Example renames [Individual ID] column to PersonalID.
EXEC sp_rename 'dbo.ExampleTable.Individual ID', 'PersonalID', 'COLUMN'

--Example Script for generating scripts to run to remove all spaces in Column Names.
--Helps my productivity more to have to only write ColumnName instead of [Column Name] each time.
DECLARE @TableName NVARCHAR(128) = 'ExampleTable' 

SELECT c.Name AS CurrentName
	  ,REPLACE(c.NAME,' ','') AS NewName
	  ,'EXEC sp_rename ''dbo.' + @TableName + '.' + c.Name + ''', ''' + REPLACE(c.Name,' ','') + ''', ''COLUMN''' AS SqlText
FROM SYS.TABLES t
	 INNER JOIN SYS.COLUMNS c ON t.OBJECT_ID = c.OBJECT_ID
WHERE t.Name = @TableName
	  AND c.Name <> REPLACE(c.Name,' ','');
	  
	  
--Example script 2: If you want to replace a character in a column name
--Below example would replace spaces with underscores. 
DECLARE @CharToReplace CHAR(1) = ' '
	   ,@CharToInsert CHAR(1) = '_'
	   ,@TableName NVARCHAR(128) = 'ExampleTable'

SELECT c.Name 
	  ,REPLACE(c.NAME,@CharToReplace,@CharToInsert) AS NewName
	  ,'EXEC sp_rename ''dbo.Raw_SupplyPlan.' + c.Name + ''', ''' + REPLACE(c.Name,@CharToReplace,@CharToInsert) + ''', ''COLUMN''' AS SqlText
FROM SYS.TABLES t
	 INNER JOIN SYS.COLUMNS c ON t.OBJECT_ID = c.OBJECT_ID
WHERE t.Name = @TableName
	  AND c.Name <> REPLACE(c.NAME,@CharToReplace,@CharToInsert);	  
	  
/* Example results: 

--From Example Script 1:
EXEC sp_rename 'dbo.ExampleTable.Individual ID', 'IndividualID', 'COLUMN'
EXEC sp_rename 'dbo.ExampleTable.Add Date', 'AddDate', 'COLUMN'

--From Example Script 2:
EXEC sp_rename 'dbo.ExampleTable.Individual ID', 'Individual_ID', 'COLUMN'
EXEC sp_rename 'dbo.ExampleTable.Add Date', 'Add_Date', 'COLUMN'

*/