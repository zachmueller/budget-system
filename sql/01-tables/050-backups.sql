USE BudgetDB
GO

IF OBJECT_ID('dbo.backups', 'U') IS NOT NULL
	DROP TABLE dbo.backups
GO


CREATE TABLE dbo.backups (
	backup_id INT IDENTITY(1,1) NOT NULL,
	workbook_id INT NOT NULL
		CONSTRAINT fk_backups_workbook_id FOREIGN KEY
		REFERENCES dbo.workbooks (workbook_id),
	backup_date DATETIME2(7) NULL,
	file_version NVARCHAR(256) NULL,
	expenses_rows_added INT NULL,
	revenue_rows_added INT NULL,
	headcount_rows_added INT NULL,
	active_backup BIT NULL,
	CONSTRAINT pk_backups 
		PRIMARY KEY CLUSTERED (backup_id)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Store metadata for all workbook backups
			from the forecasting workbooks. The backup
			feature is useful for rolling out new
			template updates to all active workbooks.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'backups';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Stores the string of the workbook version
			when creating the backup. Is selected out
			by the template VBA and can be used to
			adjust for cell location changes from
			version to version.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'backups'
	,@level2type = N'COLUMN'
	,@level2name = N'file_version';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Stores for each backup the number of
			rows, if any, that have been added to
			the Expenses tab of the forecasting
			workbook. Is used by the template workbook
			when creating from backup to add the
			necessary number of rows to the sheet
			to ensure accurate placement of
			backed-up data.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'backups'
	,@level2type = N'COLUMN'
	,@level2name = N'expenses_rows_added';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Stores for each backup the number of
			rows, if any, that have been added to
			the Revenue tab of the forecasting
			workbook. Is used by the template workbook
			when creating from backup to add the
			necessary number of rows to the sheet
			to ensure accurate placement of
			backed-up data.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'backups'
	,@level2type = N'COLUMN'
	,@level2name = N'revenue_rows_added';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Stores for each backup the number of
			rows, if any, that have been added to
			the Headcount tab of the forecasting
			workbook. Is used by the template workbook
			when creating from backup to add the
			necessary number of rows to the sheet
			to ensure accurate placement of
			backed-up data.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'backups'
	,@level2type = N'COLUMN'
	,@level2name = N'headcount_rows_added';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Can be used to hide particular backups
			from the list of available backups
			when creating from backup.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'backups'
	,@level2type = N'COLUMN'
	,@level2name = N'active_backup';
