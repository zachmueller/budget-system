USE BudgetDB
GO

IF OBJECT_ID('dbo.calculation_table_commission_attainment', 'U') IS NOT NULL
	DROP TABLE dbo.calculation_table_commission_attainment
GO


CREATE TABLE dbo.calculation_table_commission_attainment (
	scenario_id INT NOT NULL
		CONSTRAINT fk_calculation_table_commission_attainment_scenario_id FOREIGN KEY
		REFERENCES dbo.scenarios (scenario_id),
	workbook_id INT NOT NULL
		CONSTRAINT fk_calculation_table_commission_attainment_workbook_id FOREIGN KEY
		REFERENCES dbo.workbooks (workbook_id),
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
	[Month 36] DECIMAL(20, 18) NULL,
	CONSTRAINT pk_calculation_table_commission_attainment
		PRIMARY KEY CLUSTERED (scenario_id, workbook_id)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Table that maintains current assumptions for
			expected commissions attainment rates for
			each workbook.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'calculation_table_commission_attainment';
