USE BudgetDB
GO

IF TYPE_ID('dbo.settings_upload_companies') IS NOT NULL
	DROP TYPE dbo.settings_upload_companies
GO


CREATE TYPE dbo.settings_upload_companies AS TABLE(
	company_number NCHAR(3) NULL,
	company_name NVARCHAR(256) NULL,
	currency_code NCHAR(3) NULL,
	active_forecast_option BIT NULL,
	us_0_intl_1 BIT NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Receives dimension-defining data from the
			Master Assumptions workbook and applies
			changes to the dbo.companies table.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TYPE'
	,@level1name = N'settings_upload_companies';
