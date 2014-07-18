USE BudgetDB
GO

IF OBJECT_ID('dbo.calculation_table_bonus', 'U') IS NOT NULL
	DROP TABLE dbo.calculation_table_bonus
GO


CREATE TABLE dbo.calculation_table_bonus (
	scenario_id INT NOT NULL
		CONSTRAINT fk_calculation_table_bonus_scenario_id FOREIGN KEY
		REFERENCES dbo.scenarios (scenario_id),
	company_number NCHAR(3) NOT NULL
		CONSTRAINT fk_calculation_table_bonus_company_number FOREIGN KEY
		REFERENCES dbo.companies (company_number),
	bu_number NVARCHAR(100) NOT NULL
		CONSTRAINT fk_calculation_table_bonus_bu_number FOREIGN KEY
		REFERENCES dbo.business_units (bu_number),
	dept_number NCHAR(4) NOT NULL
		CONSTRAINT fk_calculation_table_bonus_dept_number FOREIGN KEY
		REFERENCES dbo.departments (dept_number),
	hfm_team_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_calculation_table_bonus_hfm_team_code FOREIGN KEY
		REFERENCES dbo.teams (hfm_team_code),
	location_number NCHAR(3) NOT NULL
		CONSTRAINT fk_calculation_table_bonus_location_number FOREIGN KEY
		REFERENCES dbo.locations (location_number),
	job_id INT NOT NULL
		CONSTRAINT fk_calculation_table_bonus_job_id FOREIGN KEY
		REFERENCES dbo.job_titles (job_id),
	ft_pt_count DECIMAL(10, 5) NULL,
	hfm_account_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_calculation_table_bonus_hfm_account_code FOREIGN KEY
		REFERENCES dbo.pl_items (hfm_account_code),
	bonus_percent DECIMAL(20, 18) NULL,
	CONSTRAINT pk_calculation_table_bonus
		PRIMARY KEY CLUSTERED (scenario_id,
		company_number, bu_number, dept_number,
		hfm_team_code, location_number, job_id,
		hfm_account_code)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Table that maintains both current and historical
			assumptions for average bonus rates for
			job titles at each different used dimension.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'calculation_table_bonus';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Total number of employees that match the record''s
			dimensions. Part time employees, or roles shared
			between multiple dimensions, are counted as
			decimal numbers.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'calculation_table_bonus'
	,@level2type = N'COLUMN'
	,@level2name = N'ft_pt_count';
