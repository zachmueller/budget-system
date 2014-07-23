USE BudgetDB
GO

IF OBJECT_ID('dbo.historical_table_team_consolidation', 'U') IS NOT NULL
	DROP TABLE dbo.historical_table_team_consolidation
GO


CREATE TABLE dbo.historical_table_team_consolidation (
	scenario_id INT NOT NULL
		CONSTRAINT fk_historical_table_team_consolidation_scenario_id FOREIGN KEY
		REFERENCES dbo.scenarios (scenario_id),
	hfm_team_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_historical_table_team_consolidation_hfm_team_code FOREIGN KEY
		REFERENCES dbo.teams (hfm_team_code),
	team_consolidation NVARCHAR(256) NULL,
	CONSTRAINT pk_historical_table_team_consolidation
		PRIMARY KEY CLUSTERED (scenario_id, hfm_team_code)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Store snapshots of team consolidation values
			(from dbo.salary_data) for each
			frozen scenario, copied at the time
			of creating the scenario.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'historical_table_team_consolidation';
