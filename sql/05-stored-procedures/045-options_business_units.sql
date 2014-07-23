USE BudgetDB
GO

IF OBJECT_ID('dbo.options_business_units', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_business_units
GO


CREATE PROCEDURE dbo.options_business_units
	@wbID INT = 0
	,@usIntl BIT = NULL
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Business Units, filtered
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
BEGIN	--	include all Business Units
	SELECT bu.bu_number, bu.bu_name
		,CASE WHEN bu.us_0_intl_1 IS NULL THEN 'Both' 
		ELSE CASE WHEN bu.us_0_intl_1=0 THEN 'US' ELSE 'INTL' END END us_intl
	FROM BudgetDB.dbo.business_units bu
	WHERE bu.active_forecast_option=1
	AND COALESCE(bu.us_0_intl_1,@usIntl,'')=ISNULL(@usIntl,'')
	ORDER BY bu.bu_name ASC
END

ELSE

BEGIN	--	only include Business Units selected in workbook
	SELECT bu.bu_number, bu.bu_name
		,CASE WHEN bu.us_0_intl_1 IS NULL THEN 'Both' 
		ELSE CASE WHEN bu.us_0_intl_1=0 THEN 'US' ELSE 'INTL' END END us_intl
	FROM BudgetDB.dbo.business_units bu
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_business_units wbbu
	ON wbbu.workbook_id=@wbID AND ISNULL(wbbu.bu_number,bu.bu_number)=bu.bu_number
	WHERE bu.active_forecast_option=1
	AND COALESCE(bu.us_0_intl_1,wb.us_0_intl_1,'')=ISNULL(wb.us_0_intl_1,'')
	ORDER BY bu.bu_name ASC
END

GO
