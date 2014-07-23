USE BudgetDB
GO

IF OBJECT_ID('dbo.options_locations', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_locations
GO


CREATE PROCEDURE dbo.options_locations
	@wbID INT = 0
	,@usIntl BIT = NULL
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Locations, filtered
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
BEGIN	--	include all Locations
	SELECT lc.location_number, lc.location_name
		,CASE WHEN lc.us_0_intl_1 IS NULL THEN 'Both' 
		ELSE CASE WHEN lc.us_0_intl_1=0 THEN 'US' ELSE 'INTL' END END us_intl
	FROM BudgetDB.dbo.locations lc
	WHERE lc.active_forecast_option=1 AND lc.real_location=1
	AND COALESCE(lc.us_0_intl_1,wb.us_0_intl_1,'')=ISNULL(wb.us_0_intl_1,'')
	ORDER BY lc.location_name ASC
END

ELSE

BEGIN	--	only include Locations selected in workbook
	SELECT lc.location_number, lc.location_name
		,CASE WHEN lc.us_0_intl_1 IS NULL THEN 'Both' 
		ELSE CASE WHEN lc.us_0_intl_1=0 THEN 'US' ELSE 'INTL' END END us_intl
	FROM BudgetDB.dbo.locations lc
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_locations wblc
	ON wblc.workbook_id=@wbID AND ISNULL(wblc.location_number,lc.location_number)=lc.location_number
	WHERE lc.active_forecast_option=1 AND lc.real_location=1
	ORDER BY lc.location_name ASC
END

GO
