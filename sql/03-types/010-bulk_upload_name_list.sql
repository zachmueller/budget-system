USE BudgetDB
GO

IF TYPE_ID('dbo.bulk_upload_name_list') IS NOT NULL
	DROP TYPE dbo.bulk_upload_name_list
GO


CREATE TYPE dbo.bulk_upload_name_list AS TABLE(
	[name] NVARCHAR(256) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Generic table type used in various stored
			procedures to import lists of dimension names.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TYPE'
	,@level1name = N'bulk_upload_name_list';
