USE BudgetDB
GO

IF OBJECT_ID('dbo.excel_get_backups_for_workbook', 'P') IS NOT NULL
	DROP PROCEDURE dbo.excel_get_backups_for_workbook
GO


CREATE PROCEDURE dbo.excel_get_backups_for_workbook
	@wbID INT
AS
/*
summary:	>
			Returns a list of all backups
			for the provided workbook ID.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

SELECT wb.workbook_name, bk.backup_id, bk.backup_date
FROM BudgetDB.dbo.backups bk
LEFT JOIN BudgetDB.dbo.workbooks wb
ON wb.workbook_id=bk.workbook_id
WHERE wb.workbook_id=@wbID
ORDER BY bk.backup_date DESC


GO
