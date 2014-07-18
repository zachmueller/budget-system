USE BudgetDB
GO

IF OBJECT_ID('dbo.cost_center_hierarchies', 'U') IS NOT NULL
	DROP TABLE dbo.cost_center_hierarchies
GO


CREATE TABLE dbo.cost_center_hierarchies (
	bu_number NVARCHAR(100) NOT NULL
		CONSTRAINT fk_cost_center_hierarchies_bu_number FOREIGN KEY  
		REFERENCES dbo.business_units (bu_number),
	dept_number NCHAR(4) NOT NULL
		CONSTRAINT fk_cost_center_hierarchies_dept_number FOREIGN KEY  
		REFERENCES dbo.departments (dept_number),
	hfm_team_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_cost_center_hierarchies_hfm_team_code FOREIGN KEY  
		REFERENCES dbo.teams (hfm_team_code),
	parent1 NVARCHAR(256) NULL,
	parent2 NVARCHAR(256) NULL,
	parent3 NVARCHAR(256) NULL,
	parent4 NVARCHAR(256) NULL,
	CONSTRAINT pk_cost_center_hierarchies 
		PRIMARY KEY CLUSTERED (bu_number,
		dept_number, hfm_team_code)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			A sit-on-top hierarchy defined and agreed
			upon by FP&A and FinOps analysts to be used
			as a simplified way to filter the P&Ls
			for views relevant to groups within
			the business.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'cost_center_hierarchies';
