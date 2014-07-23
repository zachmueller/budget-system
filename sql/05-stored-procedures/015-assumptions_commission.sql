USE BudgetDB
GO

IF OBJECT_ID('dbo.assumptions_commission', 'P') IS NOT NULL
	DROP PROCEDURE dbo.assumptions_commission
GO


CREATE PROCEDURE dbo.assumptions_commission
	@wbID INT = 0
AS
/*
summary:	>
			Download into Excel a local copy of Master Assumptions
			data relevant to each workbook, used to locally
			calculate a full P&L.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

--	test whether returning data is relevant to the provided workbook ID
--	Invalid workbook IDs and Output Only workbooks do not need to download data
IF (ISNULL((SELECT TOP 1 1-output_only
	FROM BudgetDB.dbo.workbooks
	WHERE workbook_id=@wbID),0)) = 0
BEGIN	--	select out NULL values, though keep the same structure to not interfere with the Excel layout
	SELECT NULL [company_name], NULL [bu_name],NULL [dept_name],NULL [team_consolidation],NULL [location_name]
		,NULL [job_title],NULL [exp_item], NULL [avg_commission]
END

ELSE 

BEGIN	--	select out workbook related data
	SELECT cp.company_name,bu.bu_name,dp.dept_name,ISNULL(tm.team_consolidation,tm.team_name) [team_consolidation]
		,lc.location_name,jt.job_title,pl.pl_item + ' - ' + pl.category_code [exp_item]
		,SUM(ft_pt_count*commission_percent)/SUM(ft_pt_count) [avg_commission]
	FROM BudgetDB.dbo.calculation_table_commission a
	JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=a.scenario_id
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=wb.workbook_id
		AND ISNULL(wbcp.company_number,a.company_number)=a.company_number
	JOIN BudgetDB.dbo.workbook_business_units wbbu ON wbbu.workbook_id=wb.workbook_id
		AND ISNULL(wbbu.bu_number,a.bu_number)=a.bu_number
	JOIN BudgetDB.dbo.workbook_departments wbdp ON wbdp.workbook_id=wb.workbook_id
		AND ISNULL(wbdp.dept_number,a.dept_number)=a.dept_number
	JOIN BudgetDB.dbo.workbook_teams wbtm ON wbtm.workbook_id=wb.workbook_id
		AND ISNULL(wbtm.hfm_team_code,a.hfm_team_code)=a.hfm_team_code
	JOIN BudgetDB.dbo.workbook_locations wblc ON wblc.workbook_id=wb.workbook_id
		AND ISNULL(wblc.location_number,a.location_number)=a.location_number
	JOIN BudgetDB.dbo.companies cp ON cp.company_number=a.company_number
		AND ISNULL(wb.us_0_intl_1,'')=ISNULL(cp.us_0_intl_1,'')
	LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=a.bu_number
	LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=a.dept_number
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
	LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=a.location_number
	LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
	LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=a.hfm_account_code
	GROUP BY cp.company_name,bu.bu_name,dp.dept_name,ISNULL(tm.team_consolidation,tm.team_name)
		,lc.location_name,jt.job_title,pl.pl_item + ' - ' + pl.category_code
	UNION
	SELECT cp.company_name,bu.bu_name,dp.dept_name,ISNULL(tm.team_consolidation,tm.team_name) [team_consolidation]
		,lc.location_name,jt.job_title,pl.pl_item + ' - ' + pl.category_code [exp_item]
		,SUM(ft_pt_count*commission_percent)/SUM(ft_pt_count) [avg_commission]
	FROM BudgetDB.dbo.calculation_table_commission a
	JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=a.scenario_id
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.companies cp ON cp.company_number=a.company_number
		AND ISNULL(wb.us_0_intl_1,'')=ISNULL(cp.us_0_intl_1,'')
	LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=a.bu_number
	LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=a.dept_number
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
	LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=a.location_number
	LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
	LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=a.hfm_account_code
	WHERE a.bu_number='0000' AND a.dept_number='0000'
	AND a.hfm_team_code='000' AND a.location_number='000'
	GROUP BY cp.company_name,bu.bu_name,dp.dept_name,ISNULL(tm.team_consolidation,tm.team_name)
		,lc.location_name,jt.job_title,pl.pl_item + ' - ' + pl.category_code
END

GO
