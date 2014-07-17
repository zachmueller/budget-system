USE BudgetDB
GO

IF OBJECT_ID('dbo.currencies', 'U') IS NOT NULL
	DROP TABLE dbo.currencies
GO


CREATE TABLE dbo.currencies (
	currency_code NCHAR(3) NOT NULL,
	CONSTRAINT pk_currencies 
		PRIMARY KEY (currency_code)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Maintain list of all allowable currency codes.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'currencies';
