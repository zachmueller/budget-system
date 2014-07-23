USE BudgetDB
GO

IF OBJECT_ID('dbo.update_workbook_rename', 'P') IS NOT NULL
	DROP PROCEDURE dbo.update_workbook_rename
GO


CREATE PROCEDURE dbo.update_workbook_rename
	@wbID INT
	,@newName NVARCHAR(256)
AS
/*
summary:	>
			Renames a workbook (based on its ID)
			to a new name, if the provided new
			name is not already in use.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check that workbook ID exists
IF (SELECT COUNT(*)
	FROM BudgetDB.dbo.workbooks
	WHERE workbook_id=@wbID) = 0
BEGIN
	SELECT 'Provided workbook ID does not exist in the database' o
	
	RETURN
END

--	check whether provided workbook name is already in use
IF (SELECT COUNT(*)
	FROM BudgetDB.dbo.workbooks
	WHERE workbook_name=@newName) > 0
BEGIN
	SELECT 'The new workbook name provided is already in use, please try a different name.' o
	
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:update_workbook_rename' AS VARBINARY(128))
SET CONTEXT_INFO @ci

--	update workbook name
UPDATE BudgetDB.dbo.workbooks
SET workbook_name=@newName
WHERE workbook_id=@wbID

SELECT 'Workbook name has been update successfully to "' + @newName + '".' o

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

GO
