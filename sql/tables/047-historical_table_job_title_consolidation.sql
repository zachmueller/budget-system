USE BudgetDB
GO

IF OBJECT_ID('dbo.historical_table_job_title_consolidation', 'U') IS NOT NULL
	DROP TABLE dbo.historical_table_job_title_consolidation
GO


CREATE TABLE dbo.historical_table_job_title_consolidation (
	scenario_id INT NOT NULL
		CONSTRAINT fk_historical_table_job_title_consolidation_scenario_id FOREIGN KEY
		REFERENCES dbo.scenarios (scenario_id),
	job_id INT NOT NULL
		CONSTRAINT fk_historical_table_job_title_consolidation_job_id FOREIGN KEY
		REFERENCES dbo.job_titles (job_id),
	job_consolidation NVARCHAR(256) NULL,
	CONSTRAINT pk_historical_table_job_title_consolidation
		PRIMARY KEY CLUSTERED (scenario_id, job_id)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Store snapshots of job consolidation values
			(from dbo.job_titles) for each frozen scenario,
			copied at the time of creating the scenario.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'historical_table_job_title_consolidation';
