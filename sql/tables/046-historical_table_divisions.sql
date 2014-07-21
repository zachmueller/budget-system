USE BudgetDB
GO

IF OBJECT_ID('dbo.historical_table_divisions', 'U') IS NOT NULL
	DROP TABLE dbo.historical_table_divisions
GO


CREATE TABLE dbo.historical_table_divisions (
	scenario_id INT NOT NULL
		CONSTRAINT fk_historical_table_divisions_scenario_id FOREIGN KEY
		REFERENCES dbo.scenarios (scenario_id),
	dept_number NCHAR(4) NOT NULL
		CONSTRAINT fk_historical_table_divisions_dept_number FOREIGN KEY
		REFERENCES dbo.departments (dept_number),
	bu_number NVARCHAR(100) NOT NULL
		CONSTRAINT fk_historical_table_divisions_bu_number FOREIGN KEY
		REFERENCES dbo.business_units (bu_number),
	division_name NVARCHAR(256) NULL,
	category_code NVARCHAR(50) NULL
		CONSTRAINT fk_historical_table_divisions_category_code FOREIGN KEY
		REFERENCES dbo.pl_categories (category_code),
	metric NVARCHAR(256) NULL,
	CONSTRAINT pk_historical_table_divisions
		PRIMARY KEY CLUSTERED (scenario_id, dept_number, bu_number)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Store snapshots of division mappings
			(from dbo.divisions) for each
			frozen scenario at the time of freezing
			down the scenario.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-21
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'historical_table_divisions';
