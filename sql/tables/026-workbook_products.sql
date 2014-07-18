USE BudgetDB
GO

IF OBJECT_ID('dbo.workbook_products', 'U') IS NOT NULL
	DROP TABLE dbo.workbook_products
GO


CREATE TABLE dbo.workbook_products (
	workbook_id INT NOT NULL,
	hfm_product_code NVARCHAR(100) NULL
		CONSTRAINT fk_workbook_products_hfm_product_code FOREIGN KEY
		REFERENCES dbo.products (hfm_product_code)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_workbook_products
ON dbo.workbook_products (workbook_id, hfm_product_code)
WHERE (hfm_product_code IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Defines which Products are set to be
			included for which workbooks. This mapping
			restricts what data is viewed in a workbook''s
			P&L as well as restricts what Products
			forecasting workbooks are allowed to upload.
			NULLs are used to include all Products.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'workbook_products';
