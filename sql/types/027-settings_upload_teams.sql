USE BudgetDB
GO

IF TYPE_ID('dbo.settings_upload_teams') IS NOT NULL
	DROP TYPE dbo.settings_upload_teams
GO


CREATE TYPE dbo.settings_upload_teams AS TABLE(
	hfm_team_code NVARCHAR(100) NULL,
	team_name NVARCHAR(256) NULL,
	team_consolidation NVARCHAR(256) NULL,
	active_forecast_option BIT NULL,
	us_0_intl_1 BIT NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Receives dimension-defining data from the
			Master Assumptions workbook and applies
			changes to the dbo.teams table.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TYPE'
	,@level1name = N'settings_upload_teams';
