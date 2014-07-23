USE BudgetDB
GO

IF OBJECT_ID('dbo.companies', 'U') IS NOT NULL
	DROP TABLE dbo.companies
GO


CREATE TABLE dbo.companies (
	company_number NCHAR(3) NOT NULL,
	company_name NVARCHAR(256) NULL,
	currency_code NCHAR(3) NOT NULL
		CONSTRAINT fk_companies_currency_code FOREIGN KEY  
		REFERENCES dbo.currencies (currency_code),
	active_forecast_option BIT NOT NULL,
	us_0_intl_1 BIT NOT NULL,
	hfm_company_description NVARCHAR(256) NULL,
	CONSTRAINT pk_companies 
		PRIMARY KEY CLUSTERED (company_number),
	CONSTRAINT unq_companies_company_name
		UNIQUE NONCLUSTERED (company_name)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_companies_company_name
ON dbo.companies (company_name)
WHERE (company_name IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Core dimension table that maintains the
			list of companies and maps them to the relevant
			part of HFM Entity dimension, i.e., the three
			left-most characters of the member names (with
			structure XXX_XXX).
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'companies';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Sets the default currency for each company. Used
			if no currency is set in a particular forecast
			record.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'companies'
	,@level2type = N'COLUMN'
	,@level2name = N'currency_code';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Used to differentiate between US and
			International, i.e., whether the company
			is valid for either US or International.
			0 = US
			1 = International
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'companies'
	,@level2type = N'COLUMN'
	,@level2name = N'us_0_intl_1';
