USE BudgetDB
GO

IF OBJECT_ID('dbo.backup_formulas', 'U') IS NOT NULL
	DROP TABLE dbo.backup_formulas
GO


CREATE TABLE dbo.backup_formulas (
	backup_id INT NOT NULL
		CONSTRAINT fk_backup_formulas_backup_id FOREIGN KEY
		REFERENCES dbo.backups (backup_id),
	sheet_name NVARCHAR(50) NULL,
	excel_row INT NULL,
	excel_column INT NULL,
	formula_text NVARCHAR(MAX) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Store the raw formulas and data from
			the forecasting and rollup workbooks
			for the backup feature.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'backup_formulas';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Stores the entire formula (including
			links to other Excel workbooks), or
			raw data for each cell in a workbook
			when using the backup feature.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'backup_formulas'
	,@level2type = N'COLUMN'
	,@level2name = N'formula_text';
