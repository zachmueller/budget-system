USE BudgetDB
GO

IF TYPE_ID('dbo.settings_upload_cost_center_hierarchies') IS NOT NULL
	DROP TYPE dbo.settings_upload_cost_center_hierarchies
GO


CREATE TYPE dbo.settings_upload_cost_center_hierarchies AS TABLE(
	bu_number NVARCHAR(100) NULL,
	dept_number NCHAR(4) NULL,
	hfm_team_code NVARCHAR(100) NULL,
	parent1 NVARCHAR(256) NULL,
	parent2 NVARCHAR(256) NULL,
	parent3 NVARCHAR(256) NULL,
	parent4 NVARCHAR(256) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Receives dimension-defining data from the
			Master Assumptions workbook and applies
			changes to the dbo.cost_center_hierarchies table.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TYPE'
	,@level1name = N'settings_upload_cost_center_hierarchies';
