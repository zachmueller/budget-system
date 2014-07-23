USE BudgetDB
GO

IF OBJECT_ID('dbo.frozen_versions_text', 'U') IS NOT NULL
	DROP TABLE dbo.frozen_versions_text
GO


CREATE TABLE dbo.frozen_versions_text (
	id BIGINT IDENTITY(1,1) NOT NULL,
	scenario_name NVARCHAR(256) NULL,
	company_name NVARCHAR(256) NULL,
	division_name NVARCHAR(256) NULL,
	bu_name NVARCHAR(256) NULL,
	dept_name NVARCHAR(256) NULL,
	team_name NVARCHAR(256) NULL,
	product_name NVARCHAR(256) NULL,
	location_name NVARCHAR(256) NULL,
	job_title NVARCHAR(256) NULL,
	pl_item NVARCHAR(256) NULL,
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
	workbook_name NVARCHAR(256) NULL,
	sheet_name NVARCHAR(50) NULL,
	excel_row INT NULL,
	forecast_method NVARCHAR(256) NULL,
	forecast_rate DECIMAL(30, 16) NULL,
	created_by NVARCHAR(256) NULL,
	created_date DATETIME2(7) NULL,
	last_updated_by NVARCHAR(256) NULL,
	last_updated_date DATETIME2(7) NULL,
	date_frozen DATETIME2(7) NULL,
	CONSTRAINT pk_frozen_versions_text
		PRIMARY KEY CLUSTERED (id)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Stores a copy of the data in
			dbo.frozen_versions with all text
			versions of each dimension, in
			case any changes are subsequently made
			to the individual dimension''s names.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'frozen_versions_text';
