USE BudgetDB
GO

IF OBJECT_ID('dbo.categories', 'U') IS NOT NULL
	DROP TABLE dbo.categories
GO


CREATE TABLE dbo.categories (
	category_id INT IDENTITY(1,1) NOT NULL,
	category_name NVARCHAR(256) NULL,
	us_0_intl_1 BIT NULL,
	CONSTRAINT pk_categories 
		PRIMARY KEY CLUSTERED (category_id),
	CONSTRAINT unq_categories_category_name 
		UNIQUE NONCLUSTERED (category_name)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Maintains list of user-defined categories.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'categories';
