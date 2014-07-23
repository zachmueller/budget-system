USE BudgetDB
GO

IF OBJECT_ID('dbo.update_workbook_activate', 'P') IS NOT NULL
	DROP PROCEDURE dbo.update_workbook_activate
GO


CREATE PROCEDURE dbo.update_workbook_activate
	@wbID INT
AS
/*
summary:	>
			Changes a workbook's active_workbook
			setting to 1, i.e. Active.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check that workbook ID currently exists
IF (SELECT COUNT(*)
	FROM BudgetDB.dbo.workbooks
	WHERE workbook_id=@wbID) = 0
BEGIN
	SELECT 'Provided workbook ID does not exist in the database' o
	
	RETURN
END

--	check whether workbook is currently active
IF (SELECT TOP 1 active_workbook
	FROM BudgetDB.dbo.workbooks
	WHERE workbook_id=@wbID) = 0
BEGIN
	SELECT 'Workbook is currently deactivated.' o
	
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:update_workbook_activate' AS VARBINARY(128))
SET CONTEXT_INFO @ci

--	activate workbook
UPDATE BudgetDB.dbo.workbooks
SET active_workbook=1
WHERE workbook_id=@wbID

SELECT 'Workbook has been activated successfully.' o

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

GO
