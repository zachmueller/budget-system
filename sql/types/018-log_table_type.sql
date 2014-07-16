USE BudgetDB
GO

IF TYPE_ID('log_table_type') IS NOT NULL
	DROP TYPE log_table_type
GO


CREATE TYPE log_table_type AS TABLE (
	action_taken NVARCHAR(100)
	,item_name NVARCHAR(256)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Table type used by the dbo.log_add_table_entry
			stored procedure for adding any custom items to
			the dbo.upload_log table.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-15
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TYPE'
	,@level1name = N'log_table_type';
