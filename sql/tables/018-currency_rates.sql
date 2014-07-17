USE BudgetDB
GO

IF OBJECT_ID('dbo.currency_rates', 'U') IS NOT NULL
	DROP TABLE dbo.currency_rates
GO


CREATE TABLE dbo.currency_rates (
	scenario_id INT NULL
		CONSTRAINT fk_currency_rates_scenario_id FOREIGN KEY  
		REFERENCES dbo.scenarios (scenario_id),
	from_currency NCHAR(3) NOT NULL
		CONSTRAINT fk_currency_rates_from_currency FOREIGN KEY  
		REFERENCES dbo.currencies (currency_code),
	to_currency NCHAR(3) NOT NULL
		CONSTRAINT fk_currency_rates_to_currency FOREIGN KEY  
		REFERENCES dbo.currencies (currency_code),
	conversion_type NVARCHAR(100) NOT NULL,
	conversion_month DATE NULL,
	conversion_rate DECIMAL(28, 20) NULL
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_currency_rates
ON dbo.currency_rates (scenario_id, from_currency,
	to_currency, conversion_month, conversion_type)
WHERE (scenario_id IS NOT NULL)


CREATE UNIQUE NONCLUSTERED INDEX unq_currency_rates_null
ON dbo.currency_rates (from_currency, to_currency,
	conversion_month, conversion_type)
WHERE (scenario_id IS NULL)


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Stores the foreign exchange rates for all
			forecast and budget scenarios, as well as
			stores a copy of Actual exchange rates
			pulled directly from HFM.
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


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Defines which conversion type each record
			is, to be used if adding balance sheet forecast
			data to the database.
			AVG_RATE = period average
			EOM_RATE = end of month spot rate
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'currency_rates'
	,@level2type = N'COLUMN'
	,@level2name = N'conversion_type';
