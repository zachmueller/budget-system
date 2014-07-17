USE BudgetDB
GO

IF OBJECT_ID('dbo.products', 'U') IS NOT NULL
	DROP TABLE dbo.products
GO


CREATE TABLE dbo.products (
	hfm_product_code NVARCHAR(100) NOT NULL,
	product_name NVARCHAR(256) NULL,
	product_consolidation NVARCHAR(256) NULL,
	active_forecast_option BIT NOT NULL,
	product_type_code NVARCHAR(100) NULL,
	us_0_intl_1 BIT NULL,
	hfm_product_description NVARCHAR(256) NULL,
	hfm_leaf BIT NULL,
	CONSTRAINT pk_products
		PRIMARY KEY CLUSTERED (hfm_product_code)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_products_product_name
ON dbo.products (product_name)
WHERE (product_name IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Core dimension table that maintains
			the list of all Products and
			their attributes.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'products';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Directly maps to the HFM CUSTOM3 dimension
			member values, which have the format XXXX_XXXX where
			the first 4 digits together are the Product number
			and the last 4 are the unused Future dimension
			from Oracle.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'products'
	,@level2type = N'COLUMN'
	,@level2name = N'hfm_product_code';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			DEPRECATED
			Used to include an aggregated level of the
			various products to filter by in the P&Ls.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'products'
	,@level2type = N'COLUMN'
	,@level2name = N'product_consolidation';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Maps to one of two members in the HFM
			CUSTOM3 hierarchy, PROD_DED or PROD_CLD, and
			determines which overall product type each
			product code falls under.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'products'
	,@level2type = N'COLUMN'
	,@level2name = N'product_type_code';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			DEPRECATED for dbo.products
			Used to differentiate between US and
			International, i.e., whether the Product
			is valid for either US or International.
			NULL = Both
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
	,@level1name = N'products'
	,@level2type = N'COLUMN'
	,@level2name = N'us_0_intl_1';
