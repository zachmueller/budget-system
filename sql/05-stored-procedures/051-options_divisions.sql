USE BudgetDB
GO

IF OBJECT_ID('dbo.options_divisions', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_divisions
GO


CREATE PROCEDURE dbo.options_divisions
	@wbID INT = 0
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all unique Divisions, filtered
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
BEGIN	--	include all Divisions
	SELECT DISTINCT dv.division_name 
	FROM BudgetDB.dbo.divisions dv
	ORDER BY dv.division_name ASC
END

ELSE

BEGIN	--	only include Divisions selected in workbook
	SELECT DISTINCT dv.division_name 
	FROM BudgetDB.dbo.divisions dv
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_business_units wbbu
	ON wbbu.workbook_id=@wbID AND ISNULL(wbbu.bu_number,dv.bu_number)=dv.bu_number
	JOIN BudgetDB.dbo.workbook_departments wbdp
	ON wbdp.workbook_id=@wbID AND ISNULL(wbdp.dept_number,dv.dept_number)=dv.dept_number
	JOIN BudgetDB.dbo.departments dp ON dp.dept_number=dv.dept_number
	JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=dv.bu_number
	WHERE dp.active_forecast_option=1 AND bu.active_forecast_option=1
	ORDER BY dv.division_name ASC
END

GO
