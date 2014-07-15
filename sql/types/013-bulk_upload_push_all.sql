USE BudgetDB
GO

IF TYPE_ID('bulk_upload_push_all') IS NOT NULL
	DROP TYPE bulk_upload_push_all
GO


CREATE TYPE dbo.bulk_upload_push_all AS TABLE (
	record_type NVARCHAR(50) NULL,
	sheet_name NVARCHAR(50) NULL,
	excel_row INT NULL,
	currency_code NCHAR(3) NULL,
	job_title NVARCHAR(256) NULL,
	scenario_name NVARCHAR(256) NULL,
	company_name NVARCHAR(256) NULL,
	bu_name NVARCHAR(256) NULL,
	dept_name NVARCHAR(256) NULL,
	team_name NVARCHAR(256) NULL,
	product_name NVARCHAR(256) NULL,
	location_name NVARCHAR(256) NULL,
	pl_item NVARCHAR(256) NULL,
	category NVARCHAR(256) NULL,
	description NVARCHAR(256) NULL,
	forecast_method NVARCHAR(256) NULL,
	forecast_rate DECIMAL(30, 16) NULL,
	[Month 1] DECIMAL(32, 18) NULL,
	[Month 2] DECIMAL(32, 18) NULL,
	[Month 3] DECIMAL(32, 18) NULL,
	[Month 4] DECIMAL(32, 18) NULL,
	[Month 5] DECIMAL(32, 18) NULL,
	[Month 6] DECIMAL(32, 18) NULL,
	[Month 7] DECIMAL(32, 18) NULL,
	[Month 8] DECIMAL(32, 18) NULL,
	[Month 9] DECIMAL(32, 18) NULL,
	[Month 10] DECIMAL(32, 18) NULL,
	[Month 11] DECIMAL(32, 18) NULL,
	[Month 12] DECIMAL(32, 18) NULL,
	[Month 13] DECIMAL(32, 18) NULL,
	[Month 14] DECIMAL(32, 18) NULL,
	[Month 15] DECIMAL(32, 18) NULL,
	[Month 16] DECIMAL(32, 18) NULL,
	[Month 17] DECIMAL(32, 18) NULL,
	[Month 18] DECIMAL(32, 18) NULL,
	[Month 19] DECIMAL(32, 18) NULL,
	[Month 20] DECIMAL(32, 18) NULL,
	[Month 21] DECIMAL(32, 18) NULL,
	[Month 22] DECIMAL(32, 18) NULL,
	[Month 23] DECIMAL(32, 18) NULL,
	[Month 24] DECIMAL(32, 18) NULL,
	[Month 25] DECIMAL(32, 18) NULL,
	[Month 26] DECIMAL(32, 18) NULL,
	[Month 27] DECIMAL(32, 18) NULL,
	[Month 28] DECIMAL(32, 18) NULL,
	[Month 29] DECIMAL(32, 18) NULL,
	[Month 30] DECIMAL(32, 18) NULL,
	[Month 31] DECIMAL(32, 18) NULL,
	[Month 32] DECIMAL(32, 18) NULL,
	[Month 33] DECIMAL(32, 18) NULL,
	[Month 34] DECIMAL(32, 18) NULL,
	[Month 35] DECIMAL(32, 18) NULL,
	[Month 36] DECIMAL(32, 18) NULL
)
GO


EXEC sys.sp_dropextendedproperty @name = N'MS_Description'
	,@value = N'Table type used by Excel VBA to upload the forecast data from all three forecasting sheets'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TYPE'
	,@level1name = N'bulk_upload_push_all'
