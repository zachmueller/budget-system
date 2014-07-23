USE BudgetDB
GO

IF OBJECT_ID('dbo.divisions', 'U') IS NOT NULL
	DROP TABLE dbo.divisions
GO


CREATE TABLE dbo.divisions (
	dept_number NCHAR(4) NOT NULL
		CONSTRAINT fk_divisions_dept_number FOREIGN KEY  
		REFERENCES dbo.departments (dept_number),
	bu_number NVARCHAR(100) NOT NULL
		CONSTRAINT fk_divisions_bu_number FOREIGN KEY  
		REFERENCES dbo.business_units (bu_number),
	division_name NVARCHAR(256) NULL,
	category_code NVARCHAR(50) NULL
		CONSTRAINT fk_divisions_category_code FOREIGN KEY  
		REFERENCES dbo.pl_categories (category_code),
	metric NVARCHAR(256) NULL,
	CONSTRAINT pk_divisions 
		PRIMARY KEY CLUSTERED (bu_number, dept_number)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Divisions are sit-on-top organizational
			groupings that are defined as unique
			combinations of Business Units and
			Departments
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'divisions';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Each value must be assigned to a particular
			section of the P&L and this field defines
			to which section each division is mapped. This 
			restriction is enforced both in the Application
			layer (the Excel file) as well as in the 
			database (dbo.bulk_upload_excel_push_all_updates).
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'divisions'
	,@level2type = N'COLUMN'
	,@level2name = N'category_code';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			DEPRECATED
			Ported from the old budget models as a way
			to quickly filter particular subsegments
			of the business.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'divisions'
	,@level2type = N'COLUMN'
	,@level2name = N'metric';
