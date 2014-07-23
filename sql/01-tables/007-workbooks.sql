USE BudgetDB
GO

IF OBJECT_ID('dbo.workbooks', 'U') IS NOT NULL
	DROP TABLE dbo.workbooks
GO


CREATE TABLE dbo.workbooks (
	workbook_id INT IDENTITY(1,1) NOT NULL,
	workbook_name NVARCHAR(256) NOT NULL,
	workbook_location NVARCHAR(2048) NULL,
	output_only BIT NOT NULL,
	us_0_intl_1 BIT NULL,
	active_workbook BIT NULL,
	created_by NVARCHAR(256) NULL,
	created_date DATETIME2(7) NULL,
	CONSTRAINT pk_workbooks 
		PRIMARY KEY CLUSTERED (workbook_id),
	CONSTRAINT unq_workbooks_workbook_name 
		UNIQUE NONCLUSTERED (workbook_name)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Maintains list of database-connected
			workbooks and their attributes.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'workbooks';
