USE BudgetDB
GO

IF OBJECT_ID('dbo.live_forecast', 'U') IS NOT NULL
	DROP TABLE dbo.live_forecast
GO


CREATE TABLE dbo.live_forecast (
	id INT IDENTITY(1,1) NOT NULL,
	scenario_id INT NOT NULL
		CONSTRAINT fk_live_forecast_scenario_id FOREIGN KEY  
		REFERENCES dbo.scenarios (scenario_id),
	company_number NCHAR(3) NOT NULL
		CONSTRAINT fk_live_forecast_company_number FOREIGN KEY  
		REFERENCES dbo.companies (company_number),
	bu_number NVARCHAR(100) NOT NULL
		CONSTRAINT fk_live_forecast_bu_number FOREIGN KEY  
		REFERENCES dbo.business_units (bu_number),
	dept_number NCHAR(4) NOT NULL
		CONSTRAINT fk_live_forecast_dept_number FOREIGN KEY  
		REFERENCES dbo.departments (dept_number),
	hfm_team_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_live_forecast_hfm_team_code FOREIGN KEY  
		REFERENCES dbo.teams (hfm_team_code),
	hfm_product_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_live_forecast_hfm_product_code FOREIGN KEY  
		REFERENCES dbo.products (hfm_product_code),
	location_number NCHAR(3) NOT NULL
		CONSTRAINT fk_live_forecast_location_number FOREIGN KEY  
		REFERENCES dbo.locations (location_number),
	job_id INT NULL
		CONSTRAINT fk_live_forecast_job_id FOREIGN KEY  
		REFERENCES dbo.job_titles (job_id),
	hfm_account_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_live_forecast_hfm_account_code FOREIGN KEY  
		REFERENCES dbo.pl_items (hfm_account_code),
	currency_code NCHAR(3) NULL
		CONSTRAINT fk_live_forecast_currency_code FOREIGN KEY  
		REFERENCES dbo.currencies (currency_code),
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
	category_id INT NULL
		CONSTRAINT fk_live_forecast_category_id FOREIGN KEY  
		REFERENCES dbo.categories (category_id),
	workbook_id INT NULL
		CONSTRAINT fk_live_forecast_workbook_id FOREIGN KEY  
		REFERENCES dbo.workbooks (workbook_id),
	sheet_name NVARCHAR(50) NULL,
	excel_row INT NULL,
	forecast_method NVARCHAR(256) NULL,
	forecast_rate DECIMAL(30, 16) NULL,
	created_by NVARCHAR(256) NULL,
	created_date DATETIME2(7) NULL,
	last_updated_by NVARCHAR(256) NULL,
	last_updated_date DATETIME2(7) NULL,
	CONSTRAINT pk_live_forecast
		PRIMARY KEY CLUSTERED (id)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Primary table used in the database.
			Contains all budget data for the Live
			Forecast scenario, which is the foundation
			for all calculations that feed the P&Ls
			and the frozen scenarios. Nearly all interaction
			from the application layer (Excel files)
			by the FinOps analysts flows through this table.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'live_forecast';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			The combination of workbook_id, sheet_name,
			and excel_row should always be unique and
			is the basis for matching new data from
			the application layer (Excel file) to
			the dbo.live_forecast table.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'live_forecast'
	,@level2type = N'COLUMN'
	,@level2name = N'sheet_name';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			The combination of workbook_id, sheet_name,
			and excel_row should always be unique and
			is the basis for matching new data from
			the application layer (Excel file) to
			the dbo.live_forecast table.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'live_forecast'
	,@level2type = N'COLUMN'
	,@level2name = N'excel_row';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			If data is coming from the Expenses tab
			in the Excel workbook, there are built-in
			forecasting methods from which the
			analysts may choose to aid in their
			forecasting. When a method is selected
			for a particular row, that method name
			is included in the upload.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'live_forecast'
	,@level2type = N'COLUMN'
	,@level2name = N'forecast_method';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			If data is coming from the Expenses tab
			in the Excel workbook, there are built-in
			forecasting methods from which the
			analysts may choose to aid in their
			forecasting. When a method is used
			for a particular row, any associated
			forecast rate is included in the upload.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'live_forecast'
	,@level2type = N'COLUMN'
	,@level2name = N'forecast_rate';
