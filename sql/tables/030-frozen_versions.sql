USE BudgetDB
GO

IF OBJECT_ID('dbo.frozen_versions', 'U') IS NOT NULL
	DROP TABLE dbo.frozen_versions
GO


CREATE TABLE dbo.frozen_versions (
	id BIGINT IDENTITY(1,1) NOT NULL,
	scenario_id INT NOT NULL
		CONSTRAINT fk_frozen_versions_scenario_id FOREIGN KEY  
		REFERENCES dbo.scenarios (scenario_id),
	company_number NCHAR(3) NULL,
	bu_number NVARCHAR(100) NULL,
	dept_number NCHAR(4) NULL,
	hfm_team_code NVARCHAR(100) NULL,
	hfm_product_code NVARCHAR(100) NULL,
	location_number NCHAR(3) NULL,
	job_id INT NULL,
	hfm_account_code NVARCHAR(100) NULL,
	[description] NVARCHAR(256) NULL,
	[Month 1] DECIMAL(30, 16) NULL,
	[Month 2] DECIMAL(30, 16) NULL,
	[Month 3] DECIMAL(30, 16) NULL,
	[Month 4] DECIMAL(30, 16) NULL,
	[Month 5] DECIMAL(30, 16) NULL,
	[Month 6] DECIMAL(30, 16) NULL,
	[Month 7] DECIMAL(30, 16) NULL,
	[Month 8] DECIMAL(30, 16) NULL,
	[Month 9] DECIMAL(30, 16) NULL,
	[Month 10] DECIMAL(30, 16) NULL,
	[Month 11] DECIMAL(30, 16) NULL,
	[Month 12] DECIMAL(30, 16) NULL,
	[Month 13] DECIMAL(30, 16) NULL,
	[Month 14] DECIMAL(30, 16) NULL,
	[Month 15] DECIMAL(30, 16) NULL,
	[Month 16] DECIMAL(30, 16) NULL,
	[Month 17] DECIMAL(30, 16) NULL,
	[Month 18] DECIMAL(30, 16) NULL,
	[Month 19] DECIMAL(30, 16) NULL,
	[Month 20] DECIMAL(30, 16) NULL,
	[Month 21] DECIMAL(30, 16) NULL,
	[Month 22] DECIMAL(30, 16) NULL,
	[Month 23] DECIMAL(30, 16) NULL,
	[Month 24] DECIMAL(30, 16) NULL,
	[Month 25] DECIMAL(30, 16) NULL,
	[Month 26] DECIMAL(30, 16) NULL,
	[Month 27] DECIMAL(30, 16) NULL,
	[Month 28] DECIMAL(30, 16) NULL,
	[Month 29] DECIMAL(30, 16) NULL,
	[Month 30] DECIMAL(30, 16) NULL,
	[Month 31] DECIMAL(30, 16) NULL,
	[Month 32] DECIMAL(30, 16) NULL,
	[Month 33] DECIMAL(30, 16) NULL,
	[Month 34] DECIMAL(30, 16) NULL,
	[Month 35] DECIMAL(30, 16) NULL,
	[Month 36] DECIMAL(30, 16) NULL,
	local_currency NCHAR(3) NULL,
	category_name NVARCHAR(256) NULL,
	workbook_id INT NULL,
	workbook_name NVARCHAR(256) NULL,
	sheet_name NVARCHAR(50) NULL,
	excel_row INT NULL,
	forecast_method NVARCHAR(256) NULL,
	forecast_rate DECIMAL(30, 16) NULL,
	created_by NVARCHAR(256) NULL,
	created_date DATETIME2(7) NULL,
	last_updated_by NVARCHAR(256) NULL,
	last_updated_date DATETIME2(7) NULL,
	CONSTRAINT pk_frozen_versions 
		PRIMARY KEY CLUSTERED (id)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Used for storing the budget data for
			frozen scenarios. Unlike the dbo.live_forecast
			table, dbo.frozen_versions includes all
			calculated records (e.g., base salaries,
			bonus, etc.) while the related assumptions
			are copied in separate tables to be
			able to perform detailed analyses.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'frozen_versions';
