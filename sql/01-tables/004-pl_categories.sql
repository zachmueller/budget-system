USE BudgetDB
GO

IF OBJECT_ID('dbo.pl_categories', 'U') IS NOT NULL
	DROP TABLE dbo.pl_categories
GO


CREATE TABLE dbo.pl_categories (
	category_code NVARCHAR(50) NOT NULL,
	CONSTRAINT pk_pl_categories 
		PRIMARY KEY (category_code)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Maintains list of all P&L category codes.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'pl_categories';
