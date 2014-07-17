USE BudgetDB
GO

IF TYPE_ID('dbo.bulk_upload_currency_rates') IS NOT NULL
	DROP TYPE dbo.bulk_upload_currency_rates
GO


CREATE TYPE dbo.bulk_upload_currency_rates AS TABLE(
	from_currency NCHAR(3) NULL,
	to_currency NCHAR(3) NULL,
	[Month 1] DECIMAL(28, 20) NULL,
	[Month 2] DECIMAL(28, 20) NULL,
	[Month 3] DECIMAL(28, 20) NULL,
	[Month 4] DECIMAL(28, 20) NULL,
	[Month 5] DECIMAL(28, 20) NULL,
	[Month 6] DECIMAL(28, 20) NULL,
	[Month 7] DECIMAL(28, 20) NULL,
	[Month 8] DECIMAL(28, 20) NULL,
	[Month 9] DECIMAL(28, 20) NULL,
	[Month 10] DECIMAL(28, 20) NULL,
	[Month 11] DECIMAL(28, 20) NULL,
	[Month 12] DECIMAL(28, 20) NULL,
	[Month 13] DECIMAL(28, 20) NULL,
	[Month 14] DECIMAL(28, 20) NULL,
	[Month 15] DECIMAL(28, 20) NULL,
	[Month 16] DECIMAL(28, 20) NULL,
	[Month 17] DECIMAL(28, 20) NULL,
	[Month 18] DECIMAL(28, 20) NULL,
	[Month 19] DECIMAL(28, 20) NULL,
	[Month 20] DECIMAL(28, 20) NULL,
	[Month 21] DECIMAL(28, 20) NULL,
	[Month 22] DECIMAL(28, 20) NULL,
	[Month 23] DECIMAL(28, 20) NULL,
	[Month 24] DECIMAL(28, 20) NULL,
	[Month 25] DECIMAL(28, 20) NULL,
	[Month 26] DECIMAL(28, 20) NULL,
	[Month 27] DECIMAL(28, 20) NULL,
	[Month 28] DECIMAL(28, 20) NULL,
	[Month 29] DECIMAL(28, 20) NULL,
	[Month 30] DECIMAL(28, 20) NULL,
	[Month 31] DECIMAL(28, 20) NULL,
	[Month 32] DECIMAL(28, 20) NULL,
	[Month 33] DECIMAL(28, 20) NULL,
	[Month 34] DECIMAL(28, 20) NULL,
	[Month 35] DECIMAL(28, 20) NULL,
	[Month 36] DECIMAL(28, 20) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Receives data from the Master Assumptions workbook
			to push into the relevant calculation table that
			maintains the current assumptions for monthly
			currency exchange rates.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TYPE'
	,@level1name = N'bulk_upload_currency_rates';
