USE BudgetDB
GO

IF TYPE_ID('dbo.bulk_upload_backup_cells') IS NOT NULL
	DROP TYPE dbo.bulk_upload_backup_cells
GO


CREATE TYPE dbo.bulk_upload_backup_cells AS TABLE(
	sheet_name NVARCHAR(50) NULL,
	excel_row INT NULL,
	excel_column INT NULL,
	formula_text NVARCHAR(MAX) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Allows uploading of data necessary to recreate a
			FinOps template, including any workbook links
			in addition to hard coded values.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TYPE'
	,@level1name = N'bulk_upload_backup_cells';
