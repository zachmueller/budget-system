USE BudgetDB
GO

IF OBJECT_ID('dbo.analytics_budget_to_budget', 'P') IS NOT NULL
	DROP PROCEDURE dbo.analytics_budget_to_budget
GO


CREATE PROCEDURE dbo.analytics_budget_to_budget
	@curr NCHAR(3)
	,@wbID INT
	,@startDate DATE = '2014-01-01'
	,@endDate DATE = '2014-12-01'
AS
/*
summary:	>
			UNDER DEVELOPMENT (lacks comments and hard-codes values).
			Download unpivoted budget and Actual data relevant to
			a provided workbook for analysis of changes
			from one budget scenario to another. Related Excel template
			is structured to view one trailing year of Actuals
			then the provided date range of any budget scenarios
			selected for the workbook.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-15
*/
SET NOCOUNT ON

DECLARE @fullSQL NVARCHAR(MAX)
SET @fullSQL = 'SELECT fv.scenario_id, fv.company_number, fv.bu_number
	,fv.dept_number, fv.hfm_team_code, fv.hfm_product_code
	,fv.location_number, fv.job_id, fv.hfm_account_code, fv.[description]
	,ISNULL(fv.local_currency,cp.currency_code) currency_code
	,fv.workbook_id, fv.sheet_name, fv.excel_row, sn.[start_date]
	,fv.[Month 1],fv.[Month 2],fv.[Month 3],fv.[Month 4],fv.[Month 5],fv.[Month 6]
	,fv.[Month 7],fv.[Month 8],fv.[Month 9],fv.[Month 10],fv.[Month 11],fv.[Month 12]
	,fv.[Month 13],fv.[Month 14],fv.[Month 15],fv.[Month 16],fv.[Month 17],fv.[Month 18]
	,fv.[Month 19],fv.[Month 20],fv.[Month 21],fv.[Month 22],fv.[Month 23],fv.[Month 24]
	,fv.[Month 25],fv.[Month 26],fv.[Month 27],fv.[Month 28],fv.[Month 29],fv.[Month 30]
	,fv.[Month 31],fv.[Month 32],fv.[Month 33],fv.[Month 34],fv.[Month 35],fv.[Month 36]
FROM BudgetDB.dbo.frozen_versions fv
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=fv.company_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=fv.scenario_id
' + dbo.fnOutputNarrowJoins(@wbID, 'fv') + '
JOIN BudgetDB.dbo.workbook_budgets wbbg ON wbbg.workbook_id=wb.workbook_id
	AND wbbg.scenario_id=fv.scenario_id'

IF OBJECT_ID('tempdb..#TempData') IS NOT NULL DROP TABLE #TempData

CREATE TABLE #TempData (
	scenario_id INT
	,company_number NCHAR(3)
	,bu_number NVARCHAR(100)
	,dept_number NCHAR(4)
	,hfm_team_code NVARCHAR(100)
	,hfm_product_code NVARCHAR(100)
	,location_number NCHAR(3)
	,job_id INT
	,hfm_account_code NVARCHAR(100)
	,[description] NVARCHAR(256)
	,currency_code NCHAR(3)
	,workbook_id INT
	,sheet_name NVARCHAR(50)
	,excel_row INT
	,[start_date] DATE
	,[Month 1] DECIMAL(30,16)
	,[Month 2] DECIMAL(30,16)
	,[Month 3] DECIMAL(30,16)
	,[Month 4] DECIMAL(30,16)
	,[Month 5] DECIMAL(30,16)
	,[Month 6] DECIMAL(30,16)
	,[Month 7] DECIMAL(30,16)
	,[Month 8] DECIMAL(30,16)
	,[Month 9] DECIMAL(30,16)
	,[Month 10] DECIMAL(30,16)
	,[Month 11] DECIMAL(30,16)
	,[Month 12] DECIMAL(30,16)
	,[Month 13] DECIMAL(30,16)
	,[Month 14] DECIMAL(30,16)
	,[Month 15] DECIMAL(30,16)
	,[Month 16] DECIMAL(30,16)
	,[Month 17] DECIMAL(30,16)
	,[Month 18] DECIMAL(30,16)
	,[Month 19] DECIMAL(30,16)
	,[Month 20] DECIMAL(30,16)
	,[Month 21] DECIMAL(30,16)
	,[Month 22] DECIMAL(30,16)
	,[Month 23] DECIMAL(30,16)
	,[Month 24] DECIMAL(30,16)
	,[Month 25] DECIMAL(30,16)
	,[Month 26] DECIMAL(30,16)
	,[Month 27] DECIMAL(30,16)
	,[Month 28] DECIMAL(30,16)
	,[Month 29] DECIMAL(30,16)
	,[Month 30] DECIMAL(30,16)
	,[Month 31] DECIMAL(30,16)
	,[Month 32] DECIMAL(30,16)
	,[Month 33] DECIMAL(30,16)
	,[Month 34] DECIMAL(30,16)
	,[Month 35] DECIMAL(30,16)
	,[Month 36] DECIMAL(30,16)
)

INSERT INTO #TempData
EXEC sp_executesql @fullSQL

INSERT INTO #TempData (scenario_id, company_number, bu_number
	,dept_number, hfm_team_code, location_number, hfm_product_code
	,currency_code, hfm_account_code, [start_date], [Month 1], [Month 2]
	,[Month 3], [Month 4], [Month 5], [Month 6], [Month 7], [Month 8], [Month 9]
	,[Month 10], [Month 11], [Month 12], [Month 13], [Month 14], [Month 15], [Month 16]
	,[Month 17], [Month 18], [Month 19], [Month 20], [Month 21], [Month 22], [Month 23]
	,[Month 24], [Month 25], [Month 26], [Month 27], [Month 28], [Month 29], [Month 30]
	,[Month 31], [Month 32], [Month 33], [Month 34], [Month 35], [Month 36])
SELECT sn.scenario_id
	,COALESCE(a1.company_number,a2.company_number,a3.company_number) company_number
	,COALESCE(a1.bu_number,a2.bu_number,a3.bu_number) bu_number
	,COALESCE(a1.dept_number,a2.dept_number,a3.dept_number) dept_number
	,COALESCE(a1.hfm_team_code,a2.hfm_team_code,a3.hfm_team_code) hfm_team_code
	,COALESCE(a1.location_number,a2.location_number,a3.location_number) location_number
	,COALESCE(a1.hfm_product_code,a2.hfm_product_code,a3.hfm_product_code) hfm_product_code
	,COALESCE(a1.currency_code,a2.currency_code,a3.currency_code) currency_code
	,pl.hfm_account_code
	,'2013-01-01' [start_date]
	,a1.[Month 1] [Month 1]
	,a1.[Month 2] [Month 2]
	,a1.[Month 3] [Month 3]
	,a1.[Month 4] [Month 4]
	,a1.[Month 5] [Month 5]
	,a1.[Month 6] [Month 6]
	,a1.[Month 7] [Month 7]
	,a1.[Month 8] [Month 8]
	,a1.[Month 9] [Month 9]
	,a1.[Month 10] [Month 10]
	,a1.[Month 11] [Month 11]
	,a1.[Month 12] [Month 12]
	,a2.[Month 1] [Month 13]
	,a2.[Month 2] [Month 14]
	,a2.[Month 3] [Month 15]
	,a2.[Month 4] [Month 16]
	,a2.[Month 5] [Month 17]
	,a2.[Month 6] [Month 18]
	,a2.[Month 7] [Month 19]
	,a2.[Month 8] [Month 20]
	,a2.[Month 9] [Month 21]
	,a2.[Month 10] [Month 22]
	,a2.[Month 11] [Month 23]
	,a2.[Month 12] [Month 24]
	,a3.[Month 1] [Month 25]
	,a3.[Month 2] [Month 26]
	,a3.[Month 3] [Month 27]
	,a3.[Month 4] [Month 28]
	,a3.[Month 5] [Month 29]
	,a3.[Month 6] [Month 30]
	,a3.[Month 7] [Month 31]
	,a3.[Month 8] [Month 32]
	,a3.[Month 9] [Month 33]
	,a3.[Month 10] [Month 34]
	,a3.[Month 11] [Month 35]
	,a3.[Month 12] [Month 36]
FROM (SELECT company_number, bu_number, dept_number, hfm_team_code, hfm_product_code, location_number, hfm_account_code, currency_code, [Month 1], [Month 2], [Month 3], [Month 4], [Month 5], [Month 6], [Month 7], [Month 8], [Month 9], [Month 10], [Month 11], [Month 12] FROM HFM_ActualsDB.dbo.actuals_2013 UNION ALL SELECT company_number, bu_number, dept_number, hfm_team_code, hfm_product_code, location_number, hfm_account_code, NULL currency_code, [Month 1], [Month 2], [Month 3], [Month 4], [Month 5], [Month 6], [Month 7], [Month 8], [Month 9], [Month 10], [Month 11], [Month 12] FROM HFM_ActualsDB.dbo.journal_entries_2013) a1
FULL OUTER JOIN HFM_ActualsDB.dbo.actuals_2014 a2
ON a2.company_number=a1.company_number AND a2.bu_number=a1.bu_number AND a2.dept_number=a1.dept_number AND a2.hfm_team_code=a1.hfm_team_code AND a2.hfm_product_code=a1.hfm_product_code AND a2.location_number=a1.location_number AND a2.hfm_account_code=a1.hfm_account_code AND a2.currency_code=a1.currency_code
FULL OUTER JOIN HFM_ActualsDB.dbo.actuals_2015 a3
ON a3.company_number=a1.company_number AND a3.bu_number=a1.bu_number AND a3.dept_number=a1.dept_number AND a3.hfm_team_code=a1.hfm_team_code AND a3.hfm_product_code=a1.hfm_product_code AND a3.location_number=a1.location_number AND a3.hfm_account_code=a1.hfm_account_code AND a3.currency_code=a1.currency_code
LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
JOIN BudgetDB.dbo.departments dp ON dp.dept_number=COALESCE(a1.dept_number,a2.dept_number,a3.dept_number)
JOIN BudgetDB.dbo.business_units bur ON bur.bu_number=COALESCE(a1.bu_number,a2.bu_number,a3.bu_number)
JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=bur.hist_to_current_bu_mapping
JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=COALESCE(a1.hfm_team_code,a2.hfm_team_code,a3.hfm_team_code)
JOIN BudgetDB.dbo.locations lc ON lc.location_number=COALESCE(a1.location_number,a2.location_number,a3.location_number)
JOIN BudgetDB.dbo.companies cp ON cp.company_number=COALESCE(a1.company_number,a2.company_number,a3.company_number)
	AND COALESCE(cp.us_0_intl_1,wb.us_0_intl_1,'')=ISNULL(wb.us_0_intl_1,'')
JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=COALESCE(a1.hfm_product_code,a2.hfm_product_code,a3.hfm_product_code)
JOIN BudgetDB.dbo.workbook_business_units wbbu ON wbbu.workbook_id=wb.workbook_id AND ISNULL(wbbu.bu_number,bu.bu_number)=bu.bu_number
JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=wb.workbook_id AND ISNULL(wbcp.company_number,cp.company_number)=cp.company_number
JOIN BudgetDB.dbo.workbook_departments wbdp ON wbdp.workbook_id=wb.workbook_id AND ISNULL(wbdp.dept_number,dp.dept_number)=dp.dept_number
JOIN BudgetDB.dbo.workbook_locations wblc ON wblc.workbook_id=wb.workbook_id AND ISNULL(wblc.location_number,lc.location_number)=lc.location_number
JOIN BudgetDB.dbo.workbook_products wbpd ON wbpd.workbook_id=wb.workbook_id AND ISNULL(wbpd.hfm_product_code,pd.hfm_product_code)=pd.hfm_product_code
JOIN BudgetDB.dbo.workbook_teams wbtm ON wbtm.workbook_id=wb.workbook_id AND ISNULL(wbtm.hfm_team_code,tm.hfm_team_code)=tm.hfm_team_code
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=bu.bu_number AND dv.dept_number=dp.dept_number
LEFT JOIN BudgetDB.dbo.pl_rollup plr ON plr.hfm_account_code=COALESCE(a1.hfm_account_code,a2.hfm_account_code,a3.hfm_account_code)
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=plr.hfm_account_rollup
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Actual'

-----------------------------------------

--	select out the data, unpivoted
DECLARE @minDate DATE = DATEADD(m,-12,@startDate)

SELECT sn.scenario_name [Scenario],dv.division_name [Division], cp.company_name [Company]
	,bu.bu_name [Business Unit], dp.dept_name [Department], tm.team_name [Team]
	,tm.team_consolidation [Team Consolidation], lc.location_name [Location]
	,pd.product_name [Product], jt.job_title [Job Title], u.[Description]
	,cch.parent1, cch.parent2, cch.parent3, cch.parent4
	,CASE WHEN pl.rollup_to_hosting_revenue=1 THEN 
		CASE WHEN pd.product_type_code='PROD_CLD' THEN 'Cloud Hosting Revenue'
		ELSE pl.pl_item END
	ELSE
		CASE WHEN pl.category_code IS NULL THEN pl.pl_item
		ELSE pl.pl_item + ' - ' + pl.category_code END
	END [P&L Item], u.workbook_id [Workbook], u.sheet_name [Sheet], u.excel_row [Row]
	,CAST(cx.[Date] AS DATETIME) [Date], ISNULL(cr.conversion_rate,1)*cx.[Value] [Value]
FROM #TempData u
CROSS APPLY (
	VALUES (DATEADD(m,1,start_date), [Month 1]),
(DATEADD(m,2,start_date), [Month 2]),
(DATEADD(m,3,start_date), [Month 3]),
(DATEADD(m,4,start_date), [Month 4]),
(DATEADD(m,5,start_date), [Month 5]),
(DATEADD(m,6,start_date), [Month 6]),
(DATEADD(m,7,start_date), [Month 7]),
(DATEADD(m,8,start_date), [Month 8]),
(DATEADD(m,9,start_date), [Month 9]),
(DATEADD(m,10,start_date), [Month 10]),
(DATEADD(m,11,start_date), [Month 11]),
(DATEADD(m,12,start_date), [Month 12]),
(DATEADD(m,13,start_date), [Month 13]),
(DATEADD(m,14,start_date), [Month 14]),
(DATEADD(m,15,start_date), [Month 15]),
(DATEADD(m,16,start_date), [Month 16]),
(DATEADD(m,17,start_date), [Month 17]),
(DATEADD(m,18,start_date), [Month 18]),
(DATEADD(m,19,start_date), [Month 19]),
(DATEADD(m,20,start_date), [Month 20]),
(DATEADD(m,21,start_date), [Month 21]),
(DATEADD(m,22,start_date), [Month 22]),
(DATEADD(m,23,start_date), [Month 23]),
(DATEADD(m,24,start_date), [Month 24]),
(DATEADD(m,25,start_date), [Month 25]),
(DATEADD(m,26,start_date), [Month 26]),
(DATEADD(m,27,start_date), [Month 27]),
(DATEADD(m,28,start_date), [Month 28]),
(DATEADD(m,29,start_date), [Month 29]),
(DATEADD(m,30,start_date), [Month 30]),
(DATEADD(m,31,start_date), [Month 31]),
(DATEADD(m,32,start_date), [Month 32]),
(DATEADD(m,33,start_date), [Month 33]),
(DATEADD(m,34,start_date), [Month 34]),
(DATEADD(m,35,start_date), [Month 35]),
(DATEADD(m,36,start_date), [Month 36])
) cx ([Date], [Value])
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=u.company_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=u.bu_number
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=u.dept_number
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=u.bu_number
	AND dv.dept_number=dp.dept_number
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=u.hfm_team_code
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=u.hfm_product_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=u.location_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=u.scenario_id
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=u.job_id
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=u.hfm_account_code
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=u.bu_number
	AND cch.dept_number=u.dept_number AND cch.hfm_team_code=u.hfm_team_code
LEFT JOIN BudgetDB.dbo.currency_rates cr ON cr.scenario_id=sn.scenario_id
	AND cr.from_currency=u.currency_code AND cr.to_currency=@curr
	AND cr.conversion_type='AVG_RATE' AND cr.conversion_month=cx.[Date]
WHERE cx.[Value] <> 0
AND (cx.[Date] BETWEEN @startDate AND @endDate
OR (u.scenario_id=1 AND cx.[Date]>=@minDate))

GO
