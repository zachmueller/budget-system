USE BudgetDB
GO

IF OBJECT_ID('dbo.options_product_consolidations', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_product_consolidations
GO


CREATE PROCEDURE dbo.options_product_consolidations
	@usIntl BIT = NULL
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all unique Product Consolidations,
			filtered down to only those that are
			relevant to a provided workbook ID.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

SELECT DISTINCT ISNULL(pd.product_consolidation,pd.product_name) product_consolidation
FROM BudgetDB.dbo.products pd
WHERE pd.active_forecast_option=1
AND COALESCE(pd.us_0_intl_1,@usIntl,'')=ISNULL(@usIntl,'')
ORDER BY ISNULL(pd.product_consolidation,pd.product_name) ASC

GO
