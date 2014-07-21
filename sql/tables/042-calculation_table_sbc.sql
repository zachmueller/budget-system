USE BudgetDB
GO

IF OBJECT_ID('dbo.calculation_table_sbc', 'U') IS NOT NULL
	DROP TABLE dbo.calculation_table_sbc
GO


CREATE TABLE dbo.calculation_table_sbc (
	scenario_id INT NOT NULL
		CONSTRAINT fk_calculation_table_sbc_scenario_id FOREIGN KEY
		REFERENCES dbo.scenarios (scenario_id),
	company_number NCHAR(3) NOT NULL
		CONSTRAINT fk_calculation_table_sbc_company_number FOREIGN KEY
		REFERENCES dbo.companies (company_number),
	bu_number NVARCHAR(100) NOT NULL
		CONSTRAINT fk_calculation_table_sbc_bu_number FOREIGN KEY
		REFERENCES dbo.business_units (bu_number),
	dept_number NCHAR(4) NOT NULL
		CONSTRAINT fk_calculation_table_sbc_dept_number FOREIGN KEY
		REFERENCES dbo.departments (dept_number),
	hfm_team_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_calculation_table_sbc_hfm_team_code FOREIGN KEY
		REFERENCES dbo.teams (hfm_team_code),
	location_number NCHAR(3) NOT NULL
		CONSTRAINT fk_calculation_table_sbc_location_number FOREIGN KEY
		REFERENCES dbo.locations (location_number),
	hfm_account_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_calculation_table_sbc_hfm_account_code FOREIGN KEY
		REFERENCES dbo.pl_items (hfm_account_code),
	currency_code NCHAR(3) NOT NULL
		CONSTRAINT fk_calculation_table_sbc_currency_code FOREIGN KEY
		REFERENCES dbo.currencies (currency_code),
	[Month 1] DECIMAL(30, 16) NULL,
	[Month 2] DECIMAL(30, 16) NULL,
	[Month 3] DECIMAL(30, 16) NULL,
	[Month 4] DECIMAL(30, 16) NULL,
	[Month 5] DECIMAL(30, 16) NULL,
	[Month 6] DECIMAL(30, 16) NULL,
	[Month 7] DECIMAL(30, 16) NULL,
	[Month 8] DECIMAL(30, 16) NULL,
	[Month 9] DECIMAL(30, 16) NULL,
	[Month 10] DECIMAL(30, 16) NULL,
	[Month 11] DECIMAL(30, 16) NULL,
	[Month 12] DECIMAL(30, 16) NULL,
	[Month 13] DECIMAL(30, 16) NULL,
	[Month 14] DECIMAL(30, 16) NULL,
	[Month 15] DECIMAL(30, 16) NULL,
	[Month 16] DECIMAL(30, 16) NULL,
	[Month 17] DECIMAL(30, 16) NULL,
	[Month 18] DECIMAL(30, 16) NULL,
	[Month 19] DECIMAL(30, 16) NULL,
	[Month 20] DECIMAL(30, 16) NULL,
	[Month 21] DECIMAL(30, 16) NULL,
	[Month 22] DECIMAL(30, 16) NULL,
	[Month 23] DECIMAL(30, 16) NULL,
	[Month 24] DECIMAL(30, 16) NULL,
	[Month 25] DECIMAL(30, 16) NULL,
	[Month 26] DECIMAL(30, 16) NULL,
	[Month 27] DECIMAL(30, 16) NULL,
	[Month 28] DECIMAL(30, 16) NULL,
	[Month 29] DECIMAL(30, 16) NULL,
	[Month 30] DECIMAL(30, 16) NULL,
	[Month 31] DECIMAL(30, 16) NULL,
	[Month 32] DECIMAL(30, 16) NULL,
	[Month 33] DECIMAL(30, 16) NULL,
	[Month 34] DECIMAL(30, 16) NULL,
	[Month 35] DECIMAL(30, 16) NULL,
	[Month 36] DECIMAL(30, 16) NULL,
	CONSTRAINT pk_calculation_table_sbc
		PRIMARY KEY CLUSTERED (scenario_id,
		company_number, bu_number, dept_number,
		hfm_team_code, location_number,
		hfm_account_code, currency_code)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Table that maintains both current and historical
			assumptions for stock based compensation mapped
			to each of the different dimensions.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'calculation_table_sbc';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			The related dbo.pl_items.pl_item for which
			each record''s output expense item will
			be, generally a Stock Based Comp item.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'calculation_table_sbc'
	,@level2type = N'COLUMN'
	,@level2name = N'hfm_account_code';
