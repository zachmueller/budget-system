USE BudgetDB
GO

IF OBJECT_ID('dbo.scenarios', 'U') IS NOT NULL
	DROP TABLE dbo.scenarios
GO


CREATE TABLE dbo.scenarios (
	scenario_id INT IDENTITY(1,1) NOT NULL,
	scenario_name NVARCHAR(256) NULL,
	start_date DATE NULL,
	date_frozen DATETIME2(7) NULL,
	us_0_intl_1 BIT NULL,
	rev_scenario BIT NULL,
	archived_scenario BIT NOT NULL,
	hfm_scenario NVARCHAR(100) NULL,
	CONSTRAINT pk_scenarios 
		PRIMARY KEY CLUSTERED (scenario_id),
	CONSTRAINT unq_scenarios_scenario_name 
		UNIQUE NONCLUSTERED (scenario_name)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Core dimension table to maintain list of
			scenarios and their attributes.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'';
