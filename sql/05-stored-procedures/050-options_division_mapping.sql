USE BudgetDB
GO

IF OBJECT_ID('dbo.options_division_mapping', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_division_mapping
GO


CREATE PROCEDURE dbo.options_division_mapping
	@wbID INT = 0
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Divisions (including a
			concatenation of Business Unit and
			Department to use as a lookup) and
			their P&L categories, filtered
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
	SELECT dp.dept_name + bu.bu_name dept_bu
		,dv.division_name,dv.category_code
	FROM BudgetDB.dbo.divisions dv
	LEFT JOIN BudgetDB.dbo.departments dp
	ON dp.dept_number=dv.dept_number
	LEFT JOIN BudgetDB.dbo.business_units bu
	ON bu.bu_number=dv.bu_number
	WHERE dp.active_forecast_option=1
	AND bu.active_forecast_option=1
END

ELSE

BEGIN	--	only include Divisions selected in workbook
	SELECT dp.dept_name + bu.bu_name dept_bu
		,dv.division_name,dv.category_code
	FROM BudgetDB.dbo.divisions dv
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_business_units wbbu
	ON wbbu.workbook_id=@wbID AND ISNULL(wbbu.bu_number,dv.bu_number)=dv.bu_number
	JOIN BudgetDB.dbo.workbook_departments wbdp
	ON wbdp.workbook_id=@wbID AND ISNULL(wbdp.dept_number,dv.dept_number)=dv.dept_number
	JOIN BudgetDB.dbo.departments dp ON dp.dept_number=dv.dept_number
	JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=dv.bu_number
	WHERE dp.active_forecast_option=1 AND bu.active_forecast_option=1
END

GO
