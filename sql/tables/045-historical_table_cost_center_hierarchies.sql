USE BudgetDB
GO

IF OBJECT_ID('dbo.historical_table_cost_center_hierarchies', 'U') IS NOT NULL
	DROP TABLE dbo.historical_table_cost_center_hierarchies
GO


CREATE TABLE dbo.historical_table_cost_center_hierarchies (
	scenario_id INT NOT NULL
		CONSTRAINT fk_historical_table_cost_center_hierarchies_scenario_id FOREIGN KEY
		REFERENCES dbo.scenarios (scenario_id),
	bu_number NVARCHAR(100) NOT NULL
		CONSTRAINT fk_historical_table_cost_center_hierarchies_bu_number FOREIGN KEY
		REFERENCES dbo.business_units (bu_number),
	dept_number NCHAR(4) NOT NULL
		CONSTRAINT fk_historical_table_cost_center_hierarchies_dept_number FOREIGN KEY
		REFERENCES dbo.departments (dept_number),
	hfm_team_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_historical_table_cost_center_hierarchies_hfm_team_code FOREIGN KEY
		REFERENCES dbo.teams (hfm_team_code),
	parent1 NVARCHAR(256) NULL,
	parent2 NVARCHAR(256) NULL,
	parent3 NVARCHAR(256) NULL,
	parent4 NVARCHAR(256) NULL,
	CONSTRAINT pk_historical_table_cost_center_hierarchies 
		PRIMARY KEY CLUSTERED 
		(scenario_id, bu_number,
		dept_number, hfm_team_code)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Store snapshots of cost center hierarchies
			(from dbo.cost_center_hierarchies) for each
			frozen scenario at the time of freezing
			down the scenario.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'historical_table_cost_center_hierarchies';
