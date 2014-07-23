USE BudgetDB
GO

IF OBJECT_ID('dbo.create_workbook_from_backup', 'P') IS NOT NULL
	DROP PROCEDURE dbo.create_workbook_from_backup
GO


CREATE PROCEDURE dbo.create_workbook_from_backup
	@backupID INT
AS
/*
summary:	>
			Used by any analyst (via the VBA in
			the template file) to download all
			data necessary to recreate a previously
			backed-up workbook.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

--	select out backup data
SELECT sheet_name, excel_row, excel_column, formula_text
FROM BudgetDB.dbo.backup_formulas
WHERE backup_id=@backupID

GO
