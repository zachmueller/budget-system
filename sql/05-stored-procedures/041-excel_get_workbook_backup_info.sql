USE BudgetDB
GO

IF OBJECT_ID('dbo.excel_get_workbook_backup_info', 'P') IS NOT NULL
	DROP PROCEDURE dbo.excel_get_workbook_backup_info
GO


CREATE PROCEDURE dbo.excel_get_workbook_backup_info
	@backupID INT
AS
/*
summary:	>
			Returns workbook attributes, the
			number of rows added to each of the
			Expenses/Headcount/Revenue tabs, and
			the total number of formulas needing
			to be pasted into the blank template.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

SELECT TOP 1 bk.workbook_id, wb.workbook_name, bk.expenses_rows_added
	,bk.revenue_rows_added, bk.headcount_rows_added, wb.output_only
	,f.formula_count
FROM BudgetDB.dbo.backups bk
LEFT JOIN BudgetDB.dbo.workbooks wb
ON wb.workbook_id=bk.workbook_id
LEFT JOIN (
	SELECT backup_id, COUNT(*) formula_count
	FROM BudgetDB.dbo.backup_formulas
	WHERE backup_id=@backupID
	GROUP BY backup_id
) f ON f.backup_id=bk.backup_id
WHERE bk.backup_id=@backupID

GO
