USE BudgetDB
GO

IF OBJECT_ID('dbo.options_products', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_products
GO


CREATE PROCEDURE dbo.options_products
	@wbID INT = 0
	,@usIntl BIT = NULL
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Products, filtered
			down to only those that are relevant
			to a provided workbook ID.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check workbook ID provided
IF ( @wbID=0 )
BEGIN	--	include all Products
	SELECT pd.hfm_product_code, pd.product_name, ISNULL(pd.product_consolidation,pd.product_name) product_consolidation
		,pd.product_type_code
	FROM BudgetDB.dbo.products pd
	WHERE pd.active_forecast_option=1
	AND COALESCE(pd.us_0_intl_1,wb.us_0_intl_1,'')=ISNULL(wb.us_0_intl_1,'')
	ORDER BY ISNULL(pd.product_consolidation,pd.product_name) ASC
END

ELSE

BEGIN	--	only include Products selected in workbook
	SELECT pd.hfm_product_code, pd.product_name, ISNULL(pd.product_consolidation,pd.product_name) product_consolidation
		,pd.product_type_code
	FROM BudgetDB.dbo.products pd
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_products wbpd
	ON wbpd.workbook_id=@wbID AND ISNULL(wbpd.hfm_product_code,pd.hfm_product_code)=pd.hfm_product_code
	WHERE pd.active_forecast_option=1
	AND COALESCE(pd.us_0_intl_1,wb.us_0_intl_1,'')=ISNULL(wb.us_0_intl_1,'')
	ORDER BY ISNULL(pd.product_consolidation,pd.product_name) ASC
END

GO
