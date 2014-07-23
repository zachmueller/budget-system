USE BudgetDB
GO

IF OBJECT_ID('dbo.upload_log', 'U') IS NOT NULL
	DROP TABLE dbo.upload_log
GO


CREATE TABLE dbo.upload_log (
	action_taken NVARCHAR(100) NULL,
	table_name NVARCHAR(128) NULL,
	workbook_id INT NULL,
	records_affected INT NULL,
	attribute NVARCHAR(256) NULL,
	error_message NVARCHAR(1024) NULL,
	user_name NVARCHAR(256) NULL,
	record_date DATETIME2 NULL,
	spid INT NULL,
	application_name NVARCHAR(1024) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Log any DML actions for most tables in
			the database (via triggers) as well as
			any additional desired logs through the
			procedures dbo.log_add_entry or
			dbo.log_add_table_entry.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'upload_log';
