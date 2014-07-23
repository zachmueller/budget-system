USE BudgetDB
GO

IF TYPE_ID('dbo.bulk_upload_sbc') IS NOT NULL
	DROP TYPE dbo.bulk_upload_sbc
GO


CREATE TYPE dbo.bulk_upload_sbc AS TABLE(
	participant_id NVARCHAR(256) NULL,
	company_number NCHAR(3) NULL,
	bu_number NVARCHAR(100) NULL,
	dept_number NCHAR(4) NULL,
	hfm_team_code NVARCHAR(100) NULL,
	location_number NVARCHAR(100) NULL,
	grant_number NVARCHAR(256) NULL,
	grant_type NVARCHAR(256) NULL,
	grant_date NVARCHAR(256) NULL,
	cancel_date NVARCHAR(256) NULL,
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
	[Month 16] DECIMAL(30, 16) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Receives data from the Master Assumptions workbook
			to push into the relevant calculation table that
			maintains the current assumptions for monthly
			stock based compenstation amounts.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TYPE'
	,@level1name = N'bulk_upload_sbc';
