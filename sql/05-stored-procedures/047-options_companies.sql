USE BudgetDB
GO

IF OBJECT_ID('dbo.options_companies', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_companies
GO


CREATE PROCEDURE dbo.options_companies
	@wbID INT = 0
	,@usIntl BIT = NULL
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Companies, filtered
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
BEGIN	--	include all Companies
	SELECT cp.company_number, cp.company_name
		,CASE WHEN cp.us_0_intl_1 IS NULL THEN 'Both' 
		ELSE CASE WHEN cp.us_0_intl_1=0 THEN 'US' ELSE 'INTL' END END us_intl
	FROM BudgetDB.dbo.companies cp
	WHERE cp.active_forecast_option=1
	AND COALESCE(cp.us_0_intl_1,@usIntl,'')=ISNULL(@usIntl,'')
	ORDER BY cp.company_name ASC
END

ELSE

BEGIN	--	only include Companies selected in workbook
	SELECT cp.company_number, cp.company_name
		,CASE WHEN cp.us_0_intl_1 IS NULL THEN 'Both' 
		ELSE CASE WHEN cp.us_0_intl_1=0 THEN 'US' ELSE 'INTL' END END us_intl
	FROM BudgetDB.dbo.companies cp
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_companies wbcp
	ON wbcp.workbook_id=@wbID AND ISNULL(wbcp.company_number,cp.company_number)=cp.company_number
	WHERE cp.active_forecast_option=1
	AND COALESCE(cp.us_0_intl_1,wb.us_0_intl_1,'')=ISNULL(wb.us_0_intl_1,'')
	ORDER BY cp.company_name ASC
END

GO
