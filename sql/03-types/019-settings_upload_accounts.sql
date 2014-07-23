USE BudgetDB
GO

IF TYPE_ID('dbo.settings_upload_accounts') IS NOT NULL
	DROP TYPE dbo.settings_upload_accounts
GO


CREATE TYPE dbo.settings_upload_accounts AS TABLE(
	hfm_account_code NVARCHAR(100) NULL,
	pl_item NVARCHAR(256) NULL,
	active_forecast_option BIT NULL,
	dollar_amount BIT NULL,
	hosting_revenue BIT NULL,
	category_code NVARCHAR(50) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Receives dimension-defining data from the
			Master Assumptions workbook and applies
			changes to the dbo.pl_items table.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TYPE'
	,@level1name = N'settings_upload_accounts';
