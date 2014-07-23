USE BudgetDB
GO

IF OBJECT_ID('dbo.options_job_titles', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_job_titles
GO


CREATE PROCEDURE dbo.options_job_titles
	@wbID INT = 0
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Job Titles, filtered
			down to only those that are relevant
			to a provided workbook ID.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

IF ( @wbID=0 )
BEGIN	--	include all Job Titles
	SELECT jt.job_title
	FROM BudgetDB.dbo.job_titles jt
	ORDER BY jt.job_title ASC
END

ELSE

BEGIN	--	only include Job Titles relevant to selected dimensions in workbook
	SELECT jt.job_title
	FROM BudgetDB.dbo.job_titles jt
	LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast'
	JOIN BudgetDB.dbo.workbook_business_units wbbu ON wbbu.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_departments wbdp ON wbdp.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_locations wblc ON wblc.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_teams wbtm ON wbtm.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=@wbID
	JOIN BudgetDB.dbo.calculation_table_base ba ON ba.scenario_id=sn.scenario_id
	AND ba.company_number=ISNULL(wbcp.company_number,ba.company_number)
	AND ba.bu_number=ISNULL(wbbu.bu_number,ba.bu_number)
	AND ba.dept_number=ISNULL(wbdp.dept_number,ba.dept_number)
	AND ba.location_number=ISNULL(wblc.location_number,ba.location_number)
	AND ba.hfm_team_code=ISNULL(wbtm.hfm_team_code,ba.hfm_team_code)
	AND ba.job_id=jt.job_id
	UNION
	--	also always include dummy job titles
	SELECT jt.job_title
	FROM BudgetDB.dbo.job_titles jt
	LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast'
	JOIN BudgetDB.dbo.workbook_business_units wbbu ON wbbu.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_departments wbdp ON wbdp.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_locations wblc ON wblc.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_teams wbtm ON wbtm.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=@wbID
	JOIN BudgetDB.dbo.calculation_table_base ba ON ba.scenario_id=sn.scenario_id
	AND ba.company_number=ISNULL(wbcp.company_number,ba.company_number)
	AND ba.bu_number='0000'
	AND ba.dept_number='0000'
	AND ba.location_number='000'
	AND ba.hfm_team_code='000'
	AND ba.job_id=jt.job_id
END

GO
