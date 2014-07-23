USE BudgetDB
GO

IF OBJECT_ID('dbo.excel_get_workbooks_with_backups', 'P') IS NOT NULL
	DROP PROCEDURE dbo.excel_get_workbooks_with_backups
GO


CREATE PROCEDURE dbo.excel_get_workbooks_with_backups
	@usIntl BIT = NULL
AS
/*
summary:	>
			List out all workbooks and their IDs
			that have at least one backup in
			the database.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

SELECT wb.workbook_name, wb.workbook_id
FROM BudgetDB.dbo.workbooks wb
JOIN BudgetDB.dbo.backups bk
ON bk.workbook_id=wb.workbook_id
WHERE ISNULL(wb.us_0_intl_1,'')=ISNULL(@usIntl,'')
GROUP BY wb.workbook_name, wb.workbook_id
ORDER BY MAX(bk.backup_date) DESC

GO
