USE BudgetDB
GO

IF OBJECT_ID('dbo.options_departments', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_departments
GO


CREATE PROCEDURE dbo.options_departments
	@wbID INT = 0
	,@usIntl BIT = NULL
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Departments, filtered
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
BEGIN	--	include all Departments
	SELECT dp.dept_number, dp.dept_name
		,CASE WHEN dp.us_0_intl_1 IS NULL THEN 'Both' 
		ELSE CASE WHEN dp.us_0_intl_1=0 THEN 'US' ELSE 'INTL' END END us_intl
	FROM BudgetDB.dbo.departments dp
	WHERE dp.active_forecast_option=1
	AND COALESCE(bu.us_0_intl_1,@usIntl,'')=ISNULL(@usIntl,'')
	ORDER BY dp.dept_name ASC
END

ELSE

BEGIN	--	only include Departments selected in workbook
	SELECT dp.dept_number, dp.dept_name
		,CASE WHEN dp.us_0_intl_1 IS NULL THEN 'Both' 
		ELSE CASE WHEN dp.us_0_intl_1=0 THEN 'US' ELSE 'INTL' END END us_intl
	FROM BudgetDB.dbo.departments dp
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_departments wbdp
	ON wbdp.workbook_id=@wbID AND ISNULL(wbdp.dept_number,dp.dept_number)=dp.dept_number
	WHERE dp.active_forecast_option=1
	AND COALESCE(dp.us_0_intl_1,wb.us_0_intl_1,'')=ISNULL(wb.us_0_intl_1,'')
	ORDER BY dp.dept_name ASC
END

GO
