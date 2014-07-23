USE BudgetDB
GO

IF OBJECT_ID('dbo.analytics_current_heads', 'P') IS NOT NULL
	DROP PROCEDURE dbo.analytics_current_heads
GO


CREATE PROCEDURE dbo.analytics_current_heads
	@wbID INT = NULL
	,@usIntl BIT = NULL		--	0 = US; 1 = INTL; NULL = Both
AS
/*
summary:	>
			Downloads headcount data, the total FTE count by the 
			six organizational dimensions plus Job Title, to
			reflect what currently lives in the Master Assumptions
			data tables. Designed to be easily copy/pasted into the
			FinOps templates (the Headcount tab) as a starting point
			for the budgeting process.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-15
*/
SET NOCOUNT ON

--	if no workbook ID provided, include full Headcount dump
IF ( @wbID IS NULL )
BEGIN
	SELECT cp.company_name, bu.bu_name, dp.dept_name, tm.team_name
		,pd.product_name, lc.location_name, jt.job_title
		--	aggregate by dimensions to be copy/paste-able directly
		--	into a FinOps template's Headcount tab
		,SUM(CAST(sd.ft_pt AS DECIMAL(10,5))) fte
	FROM BudgetDB.dbo.salary_data sd
	JOIN BudgetDB.dbo.companies cp ON cp.company_number=sd.company_number
		--	if US/INTL distinction selected, narrow for that, otherwise include global
		AND ISNULL(@usIntl,cp.us_0_intl_1)=cp.us_0_intl_1
	LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=sd.bu_number
	LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=sd.dept_number
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=sd.hfm_team_code
	LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code='0000_0000'
	LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=sd.location_number
	LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=sd.job_id
	GROUP BY cp.company_name, bu.bu_name, dp.dept_name, tm.team_name
		,pd.product_name, lc.location_name, jt.job_title
END
ELSE
BEGIN
	SELECT cp.company_name, bu.bu_name, dp.dept_name, tm.team_name
		,pd.product_name, lc.location_name, jt.job_title
		--	aggregate by dimensions to be copy/paste-able directly
		--	into a FinOps template's Headcount tab
		,SUM(CAST(sd.ft_pt AS DECIMAL(10,5))) fte
	FROM BudgetDB.dbo.salary_data sd
	LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=sd.company_number
	LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=sd.bu_number
	LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=sd.dept_number
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=sd.hfm_team_code
	LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code='0000_0000'
	LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=sd.location_number
	LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=sd.job_id
	--	narrow data returned based on current workbook dimensions
	JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=wb.workbook_id
	AND ISNULL(wbcp.company_number,sd.company_number)=sd.company_number
	JOIN BudgetDB.dbo.workbook_business_units wbbu ON wbbu.workbook_id=wb.workbook_id
	AND ISNULL(wbbu.bu_number,sd.bu_number)=sd.bu_number
	JOIN BudgetDB.dbo.workbook_departments wbdp ON wbdp.workbook_id=wb.workbook_id
	AND ISNULL(wbdp.dept_number,sd.dept_number)=sd.dept_number
	JOIN BudgetDB.dbo.workbook_teams wbtm ON wbtm.workbook_id=wb.workbook_id
	AND ISNULL(wbtm.hfm_team_code,sd.hfm_team_code)=sd.hfm_team_code
	JOIN BudgetDB.dbo.workbook_locations wblc ON wblc.workbook_id=wb.workbook_id
	AND ISNULL(wblc.location_number,sd.location_number)=sd.location_number
	GROUP BY cp.company_name, bu.bu_name, dp.dept_name, tm.team_name
		,pd.product_name, lc.location_name, jt.job_title
END

GO
