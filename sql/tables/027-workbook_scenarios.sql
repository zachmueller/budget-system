USE BudgetDB
GO

IF OBJECT_ID('dbo.workbook_scenarios', 'U') IS NOT NULL
	DROP TABLE dbo.workbook_scenarios
GO


CREATE TABLE dbo.workbook_scenarios (
	workbook_id INT NOT NULL,
	scenario_id INT NULL
		CONSTRAINT fk_workbook_scenarios_scenario_id FOREIGN KEY
		REFERENCES dbo.scenarios (scenario_id)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_workbook_scenarios
ON dbo.workbook_scenarios (workbook_id, scenario_id)
WHERE (scenario_id IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Defines which Scenarios are set to be
			included for which workbooks. This mapping
			restricts what data is viewed in a workbook''s
			P&L. A limit of 5 per workbook is enforced 
			at the application layer (Excel file) to 
			keep file size and refresh time down, though
			additional scenarios would be achievable.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'workbook_scenarios';
