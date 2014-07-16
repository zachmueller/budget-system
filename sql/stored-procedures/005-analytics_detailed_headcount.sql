USE BudgetDB
GO

IF OBJECT_ID('dbo.analytics_detailed_headcount', 'P') IS NOT NULL
	DROP PROCEDURE dbo.analytics_detailed_headcount
GO


CREATE PROCEDURE dbo.analytics_detailed_headcount
	@eID NVARCHAR(256) = NULL	--	employee ID, the unique identifier in the HR system
AS
/*
summary:	>
			Download detailed headcount information, such as which 
			dimensions each employee is currently mapped to and
			their job titles, from the current salary data tables.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-15
*/
SET NOCOUNT ON

--	check whether an employee ID has been provided
IF ( @eID IS NULL )
BEGIN
	--	if null employee ID, run full report
	SELECT sd.employee_id, sd.first_name, sd.last_name
		,jt.job_title, sd.ft_pt fte_count, cp.company_name
		,bu.bu_name, dp.dept_name, lc.location_name, tm.team_name
		,tm.team_consolidation, cp.company_number, bu.bu_number
		,dp.dept_number, lc.location_number, tm.hfm_team_code
	FROM BudgetDB.dbo.salary_data sd
	JOIN BudgetDB.dbo.job_titles jt
	ON jt.job_id=sd.job_id
	LEFT JOIN BudgetDB.dbo.companies cp
	ON cp.company_number=sd.company_number
	LEFT JOIN BudgetDB.dbo.business_units bu
	ON bu.bu_number=sd.bu_number
	LEFT JOIN BudgetDB.dbo.departments dp
	ON dp.dept_number=sd.dept_number
	LEFT JOIN BudgetDB.dbo.locations lc
	ON lc.location_number=sd.location_number
	LEFT JOIN BudgetDB.dbo.teams tm
	ON tm.hfm_team_code=sd.hfm_team_code
END
ELSE	--	if employee ID provided, filter based on employee ID
BEGIN
	SELECT sd.employee_id, sd.first_name, sd.last_name
		,jt.job_title, sd.ft_pt fte_count, cp.company_name
		,bu.bu_name, dp.dept_name, lc.location_name, tm.team_name
		,tm.team_consolidation, cp.company_number, bu.bu_number
		,dp.dept_number, lc.location_number, tm.hfm_team_code
	FROM BudgetDB.dbo.salary_data sd
	JOIN BudgetDB.dbo.job_titles jt
	ON jt.job_id=sd.job_id
	LEFT JOIN BudgetDB.dbo.companies cp
	ON cp.company_number=sd.company_number
	LEFT JOIN BudgetDB.dbo.business_units bu
	ON bu.bu_number=sd.bu_number
	LEFT JOIN BudgetDB.dbo.departments dp
	ON dp.dept_number=sd.dept_number
	LEFT JOIN BudgetDB.dbo.locations lc
	ON lc.location_number=sd.location_number
	LEFT JOIN BudgetDB.dbo.teams tm
	ON tm.hfm_team_code=sd.hfm_team_code
	WHERE sd.employee_id=@eID
END

GO
