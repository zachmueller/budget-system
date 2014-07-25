USE HFM_ActualsDB
GO

IF OBJECT_ID('dbo.journal_entries_2013', 'U') IS NOT NULL
	DROP TABLE dbo.journal_entries_2013
GO


CREATE TABLE dbo.journal_entries_2013 (
	company_number NCHAR(3) NULL,
	location_number NCHAR(3) NULL,
	hfm_account_code NVARCHAR(100) NULL,
	bu_number NCHAR(4) NULL,
	dept_number NCHAR(4) NULL,
	hfm_team_code NVARCHAR(100) NULL,
	hfm_product_code NVARCHAR(100) NULL,
	[Month 1] DECIMAL(38, 12) NOT NULL,
	[Month 2] DECIMAL(38, 12) NULL,
	[Month 3] DECIMAL(38, 12) NULL,
	[Month 4] DECIMAL(38, 12) NULL,
	[Month 5] DECIMAL(38, 12) NULL,
	[Month 6] DECIMAL(38, 12) NULL,
	[Month 7] DECIMAL(38, 12) NULL,
	[Month 8] DECIMAL(38, 12) NULL,
	[Month 9] DECIMAL(38, 12) NULL,
	[Month 10] DECIMAL(38, 12) NULL,
	[Month 11] DECIMAL(38, 12) NULL,
	[Month 12] DECIMAL(38, 12) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Contains the data pertaining to the
			manual journal entries that were
			booked in HFM during the first half
			of 2013. The practice of using HFM
			to store journal entries was ended
			in July of that year, as it was
			found to cause more difficulty in
			understanding the financials.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-25
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'journal_entries_2013';
