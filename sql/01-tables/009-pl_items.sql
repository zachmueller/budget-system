USE BudgetDB
GO

IF OBJECT_ID('dbo.pl_items', 'U') IS NOT NULL
	DROP TABLE dbo.pl_items
GO


CREATE TABLE dbo.pl_items (
	hfm_account_code NVARCHAR(100) NOT NULL,
	pl_item NVARCHAR(256) NULL,
	active_forecast_option BIT NOT NULL,
	dollar_amount BIT NOT NULL,
	rollup_to_hosting_revenue BIT NULL,
	category_code NVARCHAR(50) NULL
		CONSTRAINT fk_pl_items_category_code FOREIGN KEY  
		REFERENCES dbo.pl_categories (category_code),
	hfm_account_description NVARCHAR(256) NULL,
	hfm_leaf BIT NULL,
	CONSTRAINT pk_pl_items
		PRIMARY KEY CLUSTERED (hfm_account_code)
)
GO

CREATE UNIQUE NONCLUSTERED INDEX unq_pl_items_pl_item_category_code 
ON dbo.pl_items (pl_item, category_code)
WHERE (pl_item IS NOT NULL)


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Core dimension table that maintains the
			list of P&L line items as well as maps
			the HFM Account hierarchy to the P&L.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'pl_items';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Exact match for the HFM Account dimension
			member values.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'pl_items'
	,@level1type = N'COLUMN'
	,@level1name = N'hfm_account_code';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			The name of the P&L line item that exactly
			matches the value in the Excel P&L, including
			the category_code when it is not null.
			Example: pl_item + '' - '' + category_code
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'pl_items'
	,@level1type = N'COLUMN'
	,@level1name = N'pl_item';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Used to determine whether foreign exchange
			rates will be applied during P&L refreshes
			for workbooks refreshing in currencies
			other than the record'' default.
			Example: Headcount should not be converted
			when viewing across currencies, thus
			it''s dollar_amount value would be 0.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'pl_items'
	,@level1type = N'COLUMN'
	,@level1name = N'dollar_amount';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Determines whether the P&L line item
			is a revenue item and whether it flows into
			Hosting Revenue on the P&L. This is used
			(in conjunction with the product code)
			when summing up forecast data locally on the
			Local P&L, where Cloud revenue may flow into
			either Cloud Hosting Revenue or stay separated
			in Credits and One Time Revenue line items.
			Settings: NULL = expense item
			0 = revenue item, does not flow into
			hosting revenue
			1 = revenue item, does flow into
			hosting revenue
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'pl_items'
	,@level1type = N'COLUMN'
	,@level1name = N'rollup_to_hosting_revenue';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Expense P&L line items fall into any of a
			few different sections on the P&L, such as
			Cost of Revenue or G&A. Used in the P&L
			refresh to append its value when necessary.
			Example: pl_item + '' - '' + category_code
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'pl_items'
	,@level1type = N'COLUMN'
	,@level1name = N'category_code';
