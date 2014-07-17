USE BudgetDB
GO

IF OBJECT_ID('dbo.currency_rates', 'U') IS NOT NULL
	DROP TABLE dbo.currency_rates
GO


CREATE TABLE dbo.currency_rates (
	scenario_id INT NULL,
	from_currency NCHAR(3) NOT NULL,
	to_currency NCHAR(3) NOT NULL,
	conversion_type NVARCHAR(100) NOT NULL,
	conversion_month DATE NULL,
	conversion_rate DECIMAL(28, 20) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Description here.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'currency_rates';
