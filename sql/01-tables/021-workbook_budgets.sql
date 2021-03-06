USE BudgetDB
GO

IF OBJECT_ID('dbo.workbook_budgets', 'U') IS NOT NULL
	DROP PROCEDURE dbo.workbook_budgets
GO


CREATE TABLE dbo.workbook_budgets (
	workbook_id INT NOT NULL
		CONSTRAINT fk_workbook_budgets_workbook_id FOREIGN KEY  
		REFERENCES dbo.workbooks (workbook_id),
	scenario_id INT NOT NULL
		CONSTRAINT fk_workbook_budgets_scenario_id FOREIGN KEY  
		REFERENCES dbo.scenarios (scenario_id),
	CONSTRAINT pk_workbook_budgets
		PRIMARY KEY CLUSTERED (workbook_id, scenario_id)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Table to track which budget (frozen) scenarios are
			set to be included for each workbook, used when
			downloading P&L data for Budget to Budget analysis
			(the dbo.analytics_budget_to_budget procedure).
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-15
- version 2:
		Modification: Changed DDL to be consistent with other tables
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'workbook_budgets';
