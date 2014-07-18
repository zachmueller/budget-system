USE BudgetDB
GO

IF OBJECT_ID('dbo.calculation_table_salary_payroll_taxes', 'U') IS NOT NULL
	DROP TABLE dbo.calculation_table_salary_payroll_taxes
GO


CREATE TABLE dbo.calculation_table_salary_payroll_taxes (
	scenario_id INT NOT NULL
		CONSTRAINT fk_calculation_table_salary_payroll_taxes_scenario_id FOREIGN KEY
		REFERENCES dbo.scenarios (scenario_id),
	company_number NCHAR(3) NOT NULL
		CONSTRAINT fk_calculation_table_salary_payroll_taxes_company_number FOREIGN KEY
		REFERENCES dbo.companies (company_number),
	bu_number NVARCHAR(100) NULL
		CONSTRAINT fk_calculation_table_salary_payroll_taxes_bu_number FOREIGN KEY
		REFERENCES dbo.business_units (bu_number),
	hfm_account_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_calculation_table_salary_payroll_taxes_hfm_account_code FOREIGN KEY
		REFERENCES dbo.pl_items (hfm_account_code),
	[Month 1] DECIMAL(20, 18) NULL,
	[Month 2] DECIMAL(20, 18) NULL,
	[Month 3] DECIMAL(20, 18) NULL,
	[Month 4] DECIMAL(20, 18) NULL,
	[Month 5] DECIMAL(20, 18) NULL,
	[Month 6] DECIMAL(20, 18) NULL,
	[Month 7] DECIMAL(20, 18) NULL,
	[Month 8] DECIMAL(20, 18) NULL,
	[Month 9] DECIMAL(20, 18) NULL,
	[Month 10] DECIMAL(20, 18) NULL,
	[Month 11] DECIMAL(20, 18) NULL,
	[Month 12] DECIMAL(20, 18) NULL,
	[Month 13] DECIMAL(20, 18) NULL,
	[Month 14] DECIMAL(20, 18) NULL,
	[Month 15] DECIMAL(20, 18) NULL,
	[Month 16] DECIMAL(20, 18) NULL,
	[Month 17] DECIMAL(20, 18) NULL,
	[Month 18] DECIMAL(20, 18) NULL,
	[Month 19] DECIMAL(20, 18) NULL,
	[Month 20] DECIMAL(20, 18) NULL,
	[Month 21] DECIMAL(20, 18) NULL,
	[Month 22] DECIMAL(20, 18) NULL,
	[Month 23] DECIMAL(20, 18) NULL,
	[Month 24] DECIMAL(20, 18) NULL,
	[Month 25] DECIMAL(20, 18) NULL,
	[Month 26] DECIMAL(20, 18) NULL,
	[Month 27] DECIMAL(20, 18) NULL,
	[Month 28] DECIMAL(20, 18) NULL,
	[Month 29] DECIMAL(20, 18) NULL,
	[Month 30] DECIMAL(20, 18) NULL,
	[Month 31] DECIMAL(20, 18) NULL,
	[Month 32] DECIMAL(20, 18) NULL,
	[Month 33] DECIMAL(20, 18) NULL,
	[Month 34] DECIMAL(20, 18) NULL,
	[Month 35] DECIMAL(20, 18) NULL,
	[Month 36] DECIMAL(20, 18) NULL
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_calculation_table_salary_payroll_taxes
ON dbo.calculation_table_salary_payroll_taxes (scenario_id, company_number,
	bu_number, hfm_account_code)
WHERE (bu_number IS NOT NULL)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_calculation_table_salary_payroll_taxes_null
ON dbo.calculation_table_salary_payroll_taxes (scenario_id, company_number, hfm_account_code)
WHERE (bu_number IS NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Table that maintains both current and historical
			assumptions for payroll tax rates for salaries.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'calculation_table_salary_payroll_taxes';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			The related dbo.pl_items.pl_item for which
			each record''s output expense item will
			be, generally a payroll tax item.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'calculation_table_salary_payroll_taxes'
	,@level2type = N'COLUMN'
	,@level2name = N'hfm_account_code';
