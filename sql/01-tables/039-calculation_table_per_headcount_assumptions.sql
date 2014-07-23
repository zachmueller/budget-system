USE BudgetDB
GO

IF OBJECT_ID('dbo.calculation_table_per_headcount_assumptions', 'U') IS NOT NULL
	DROP TABLE dbo.calculation_table_per_headcount_assumptions
GO


CREATE TABLE dbo.calculation_table_per_headcount_assumptions (
	scenario_id INT NOT NULL
		CONSTRAINT fk_calculation_table_per_headcount_assumptions_scenario_id FOREIGN KEY
		REFERENCES dbo.scenarios (scenario_id),
	company_number NCHAR(3) NOT NULL
		CONSTRAINT fk_calculation_table_per_headcount_assumptions_company_number FOREIGN KEY
		REFERENCES dbo.companies (company_number),
	hfm_account_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_calculation_table_per_headcount_assumptions_hfm_account_code FOREIGN KEY
		REFERENCES dbo.pl_items (hfm_account_code),
	currency_code NCHAR(3) NOT NULL
		CONSTRAINT fk_calculation_table_per_headcount_assumptions_currency_code FOREIGN KEY
		REFERENCES dbo.currencies (currency_code),
	[Month 1] DECIMAl(30, 16) NULL,
	[Month 2] DECIMAl(30, 16) NULL,
	[Month 3] DECIMAl(30, 16) NULL,
	[Month 4] DECIMAl(30, 16) NULL,
	[Month 5] DECIMAl(30, 16) NULL,
	[Month 6] DECIMAl(30, 16) NULL,
	[Month 7] DECIMAl(30, 16) NULL,
	[Month 8] DECIMAl(30, 16) NULL,
	[Month 9] DECIMAl(30, 16) NULL,
	[Month 10] DECIMAl(30, 16) NULL,
	[Month 11] DECIMAl(30, 16) NULL,
	[Month 12] DECIMAl(30, 16) NULL,
	[Month 13] DECIMAl(30, 16) NULL,
	[Month 14] DECIMAl(30, 16) NULL,
	[Month 15] DECIMAl(30, 16) NULL,
	[Month 16] DECIMAl(30, 16) NULL,
	[Month 17] DECIMAl(30, 16) NULL,
	[Month 18] DECIMAl(30, 16) NULL,
	[Month 19] DECIMAl(30, 16) NULL,
	[Month 20] DECIMAl(30, 16) NULL,
	[Month 21] DECIMAl(30, 16) NULL,
	[Month 22] DECIMAl(30, 16) NULL,
	[Month 23] DECIMAl(30, 16) NULL,
	[Month 24] DECIMAl(30, 16) NULL,
	[Month 25] DECIMAl(30, 16) NULL,
	[Month 26] DECIMAl(30, 16) NULL,
	[Month 27] DECIMAl(30, 16) NULL,
	[Month 28] DECIMAl(30, 16) NULL,
	[Month 29] DECIMAl(30, 16) NULL,
	[Month 30] DECIMAl(30, 16) NULL,
	[Month 31] DECIMAl(30, 16) NULL,
	[Month 32] DECIMAl(30, 16) NULL,
	[Month 33] DECIMAl(30, 16) NULL,
	[Month 34] DECIMAl(30, 16) NULL,
	[Month 35] DECIMAl(30, 16) NULL,
	[Month 36] DECIMAl(30, 16) NULL,
	CONSTRAINT pk_calculation_table_per_headcount_assumptions
		PRIMARY KEY CLUSTERED (scenario_id, company_number,
		hfm_account_code, currency_code)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Table that maintains both current and historical
			assumptions for costs that are tied directly
			to number of heads (i.e., there are $X per
			each additional head).
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'calculation_table_per_headcount_assumptions';
