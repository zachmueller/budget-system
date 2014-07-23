USE BudgetDB
GO

IF OBJECT_ID('dbo.departments', 'U') IS NOT NULL
	DROP TABLE dbo.departments
GO


CREATE TABLE dbo.departments (
	dept_number NCHAR(4) NOT NULL,
	dept_name NVARCHAR(256) NULL,
	active_forecast_option BIT NOT NULL,
	us_0_intl_1 BIT NULL,
	hfm_dept_description NVARCHAR(256) NULL,
	CONSTRAINT pk_departments
		PRIMARY KEY CLUSTERED (dept_number)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_departments_dept_name
ON dbo.departments (dept_name)
WHERE (dept_name IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Core dimension table that maintains
			the list of all Departments and
			their attributes.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'departments';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Directly maps to part of the HFM CUSTOM1 dimension
			member values, which have the format XXXX_XXXX where
			the last 4 digits together are the Department number.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'departments'
	,@level2type = N'COLUMN'
	,@level2name = N'dept_number';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			DEPRECATED for dbo.departments
			Used to differentiate between US and
			International, i.e., whether the Department
			is valid for either US or International.
			NULL = Both
			0 = US
			1 = International
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'departments'
	,@level2type = N'COLUMN'
	,@level2name = N'us_0_intl_1';
