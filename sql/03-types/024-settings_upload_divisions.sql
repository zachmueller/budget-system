USE BudgetDB
GO

IF TYPE_ID('dbo.settings_upload_divisions') IS NOT NULL
	DROP TYPE dbo.settings_upload_divisions
GO


CREATE TYPE dbo.settings_upload_divisions AS TABLE(
	dept_number NCHAR(4) NULL,
	bu_number NVARCHAR(100) NULL,
	metric NVARCHAR(256) NULL,
	division_name NVARCHAR(256) NULL,
	category_code NVARCHAR(50) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Receives dimension-defining data from the
			Master Assumptions workbook and applies
			changes to the dbo.divisions table.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TYPE'
	,@level1name = N'settings_upload_divisions';
