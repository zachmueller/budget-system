USE BudgetDB
GO

IF OBJECT_ID('dbo.analytics_headcount', 'P') IS NOT NULL
	DROP PROCEDURE dbo.analytics_headcount
GO


CREATE PROCEDURE dbo.analytics_headcount
	@curr NCHAR(3) = 'USD'				--	currency code
	,@startMonth DATE
	,@endMonth DATE
	,@sn NVARCHAR(256) = 'Forecast'		--	scenario name
	,@wbID INT = NULL					--	workbook ID
AS
/*
summary:	>
			Download an unpivoted data set that contains detailed
			headcount numbers (e.g., average annual salary, expensed
			vs capitalized base/bonus/etc.) that the analysts can
			use for thorough headcount analytics.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-15
*/
SET NOCOUNT ON

--	check whether scenario exists
IF (SELECT TOP 1 scenario_id
	FROM BudgetDB.dbo.scenarios
	WHERE scenario_name=@sn) IS NULL
BEGIN
	SELECT 'Provided scenario name not found in the database.' error
	RETURN
END

--	collect scenario ID
DECLARE @scenarioID INT = (
	SELECT TOP 1 scenario_id
	FROM BudgetDB.dbo.scenarios
	WHERE scenario_name=@sn)

--	drop old temp tables
IF OBJECT_ID('tempdb..#TempAvgBase') IS NOT NULL DROP TABLE #TempAvgBase
IF OBJECT_ID('tempdb..#TempAvgBonus') IS NOT NULL DROP TABLE #TempAvgBonus
IF OBJECT_ID('tempdb..#TempAvgCommission') IS NOT NULL DROP TABLE #TempAvgCommission
IF OBJECT_ID('tempdb..#TempSalaries') IS NOT NULL DROP TABLE #TempSalaries
IF OBJECT_ID('tempdb..#TempDummySalaries') IS NOT NULL DROP TABLE #TempDummySalaries
IF OBJECT_ID('tempdb..#TempCapRates') IS NOT NULL DROP TABLE #TempCapRates
IF OBJECT_ID('tempdb..#TempBudget') IS NOT NULL DROP TABLE #TempBudget

--	create temp tables to hold intermediate results
--	for more efficient unpivoting
CREATE TABLE #TempAvgBase (
	scenario_id INT
	,company_number NCHAR(3)
	,bu_number NVARCHAR(100)
	,dept_number NCHAR(4)
	,hfm_team_code NVARCHAR(256)
	,location_number NCHAR(3)
	,job_id INT
	,hfm_account_code NVARCHAR(100)
	,dummy_job BIT
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

CREATE TABLE #TempAvgBonus (
	scenario_id INT
	,company_number NCHAR(3)
	,bu_number NVARCHAR(100)
	,dept_number NCHAR(4)
	,hfm_team_code NVARCHAR(256)
	,location_number NCHAR(3)
	,job_id INT
	,hfm_account_code NVARCHAR(100)
	,dummy_job BIT
	,avg_bonus DECIMAL(20,18)
)

CREATE TABLE #TempAvgCommission (
	scenario_id INT
	,company_number NCHAR(3)
	,bu_number NVARCHAR(100)
	,dept_number NCHAR(4)
	,hfm_team_code NVARCHAR(256)
	,location_number NCHAR(3)
	,job_id INT
	,hfm_account_code NVARCHAR(100)
	,dummy_job BIT
	,avg_commission DECIMAL(20,18)
)

CREATE TABLE #TempCapRates (
	id INT
	,[Month 1] DECIMAL(12,8)
	,[Month 2] DECIMAL(12,8)
	,[Month 3] DECIMAL(12,8)
	,[Month 4] DECIMAL(12,8)
	,[Month 5] DECIMAL(12,8)
	,[Month 6] DECIMAL(12,8)
	,[Month 7] DECIMAL(12,8)
	,[Month 8] DECIMAL(12,8)
	,[Month 9] DECIMAL(12,8)
	,[Month 10] DECIMAL(12,8)
	,[Month 11] DECIMAL(12,8)
	,[Month 12] DECIMAL(12,8)
	,[Month 13] DECIMAL(12,8)
	,[Month 14] DECIMAL(12,8)
	,[Month 15] DECIMAL(12,8)
	,[Month 16] DECIMAL(12,8)
	,[Month 17] DECIMAL(12,8)
	,[Month 18] DECIMAL(12,8)
	,[Month 19] DECIMAL(12,8)
	,[Month 20] DECIMAL(12,8)
	,[Month 21] DECIMAL(12,8)
	,[Month 22] DECIMAL(12,8)
	,[Month 23] DECIMAL(12,8)
	,[Month 24] DECIMAL(12,8)
	,[Month 25] DECIMAL(12,8)
	,[Month 26] DECIMAL(12,8)
	,[Month 27] DECIMAL(12,8)
	,[Month 28] DECIMAL(12,8)
	,[Month 29] DECIMAL(12,8)
	,[Month 30] DECIMAL(12,8)
	,[Month 31] DECIMAL(12,8)
	,[Month 32] DECIMAL(12,8)
	,[Month 33] DECIMAL(12,8)
	,[Month 34] DECIMAL(12,8)
	,[Month 35] DECIMAL(12,8)
	,[Month 36] DECIMAL(12,8)
)

CREATE TABLE #TempSalaries (
	company_name NVARCHAR(256)
	,location_name NVARCHAR(256)
	,bu_name NVARCHAR(256)
	,dept_name NVARCHAR(256)
	,team_consolidation NVARCHAR(256)
	,job_title NVARCHAR(256)
	,avg_base DECIMAL(30,16)
	,avg_bonus DECIMAL(30,16)
	,avg_commission DECIMAL(30,16)
	,currency_code NCHAR(3)
)

CREATE TABLE #TempDummySalaries (
	job_title NVARCHAR(256)
	,avg_base DECIMAL(30,16)
	,avg_bonus DECIMAL(30,16)
	,avg_commission DECIMAL(30,16)
	,currency_code NCHAR(3)
)

CREATE TABLE #TempBudget (
	id INT
	,scenario_id INT
	,company_number NCHAR(3)
	,bu_number NVARCHAR(100)
	,dept_number NCHAR(4)
	,hfm_team_code NVARCHAR(100)
	,hfm_product_code NVARCHAR(100)
	,location_number NCHAR(3)
	,job_id INT
	,hfm_account_code NVARCHAR(100)
	,[description] NVARCHAR(256)
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
	,category_id INT
	,category_name NVARCHAR(256)
	,workbook_id INT
	,workbook_name NVARCHAR(256)
	,sheet_name NVARCHAR(50)
	,excel_row INT
	,forecast_method NVARCHAR(256)
	,forecast_rate DECIMAL(30,16)
	,created_by NVARCHAR(256)
	,created_date DATETIME2
	,last_updated_by NVARCHAR(256)
	,last_updated_date DATETIME2
	,currency_code NCHAR(3)
)

--	if Forecast scenario provided, reference live_forecast and related tables
IF ( @sn = 'Forecast' )
BEGIN
	--	avg base
	INSERT INTO #TempAvgBase (scenario_id, company_number, bu_number, dept_number, hfm_team_code
		,location_number, job_id, hfm_account_code, dummy_job
		,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6]
		,[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12]
		,[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
		,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
		,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30]
		,[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
	SELECT a.scenario_id, a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) hfm_team_code
		,a.location_number,a.job_id,a.hfm_account_code,CASE WHEN LEFT(jt.job_title,5)='dummy' THEN 1 ELSE 0 END dummy_job
		,SUM(a.ft_pt_count*[Month 1])/SUM(a.ft_pt_count) [Month 1]
		,SUM(a.ft_pt_count*[Month 2])/SUM(a.ft_pt_count) [Month 2]
		,SUM(a.ft_pt_count*[Month 3])/SUM(a.ft_pt_count) [Month 3]
		,SUM(a.ft_pt_count*[Month 4])/SUM(a.ft_pt_count) [Month 4]
		,SUM(a.ft_pt_count*[Month 5])/SUM(a.ft_pt_count) [Month 5]
		,SUM(a.ft_pt_count*[Month 6])/SUM(a.ft_pt_count) [Month 6]
		,SUM(a.ft_pt_count*[Month 7])/SUM(a.ft_pt_count) [Month 7]
		,SUM(a.ft_pt_count*[Month 8])/SUM(a.ft_pt_count) [Month 8]
		,SUM(a.ft_pt_count*[Month 9])/SUM(a.ft_pt_count) [Month 9]
		,SUM(a.ft_pt_count*[Month 10])/SUM(a.ft_pt_count) [Month 10]
		,SUM(a.ft_pt_count*[Month 11])/SUM(a.ft_pt_count) [Month 11]
		,SUM(a.ft_pt_count*[Month 12])/SUM(a.ft_pt_count) [Month 12]
		,SUM(a.ft_pt_count*[Month 13])/SUM(a.ft_pt_count) [Month 13]
		,SUM(a.ft_pt_count*[Month 14])/SUM(a.ft_pt_count) [Month 14]
		,SUM(a.ft_pt_count*[Month 15])/SUM(a.ft_pt_count) [Month 15]
		,SUM(a.ft_pt_count*[Month 16])/SUM(a.ft_pt_count) [Month 16]
		,SUM(a.ft_pt_count*[Month 17])/SUM(a.ft_pt_count) [Month 17]
		,SUM(a.ft_pt_count*[Month 18])/SUM(a.ft_pt_count) [Month 18]
		,SUM(a.ft_pt_count*[Month 19])/SUM(a.ft_pt_count) [Month 19]
		,SUM(a.ft_pt_count*[Month 20])/SUM(a.ft_pt_count) [Month 20]
		,SUM(a.ft_pt_count*[Month 21])/SUM(a.ft_pt_count) [Month 21]
		,SUM(a.ft_pt_count*[Month 22])/SUM(a.ft_pt_count) [Month 22]
		,SUM(a.ft_pt_count*[Month 23])/SUM(a.ft_pt_count) [Month 23]
		,SUM(a.ft_pt_count*[Month 24])/SUM(a.ft_pt_count) [Month 24]
		,SUM(a.ft_pt_count*[Month 25])/SUM(a.ft_pt_count) [Month 25]
		,SUM(a.ft_pt_count*[Month 26])/SUM(a.ft_pt_count) [Month 26]
		,SUM(a.ft_pt_count*[Month 27])/SUM(a.ft_pt_count) [Month 27]
		,SUM(a.ft_pt_count*[Month 28])/SUM(a.ft_pt_count) [Month 28]
		,SUM(a.ft_pt_count*[Month 29])/SUM(a.ft_pt_count) [Month 29]
		,SUM(a.ft_pt_count*[Month 30])/SUM(a.ft_pt_count) [Month 30]
		,SUM(a.ft_pt_count*[Month 31])/SUM(a.ft_pt_count) [Month 31]
		,SUM(a.ft_pt_count*[Month 32])/SUM(a.ft_pt_count) [Month 32]
		,SUM(a.ft_pt_count*[Month 33])/SUM(a.ft_pt_count) [Month 33]
		,SUM(a.ft_pt_count*[Month 34])/SUM(a.ft_pt_count) [Month 34]
		,SUM(a.ft_pt_count*[Month 35])/SUM(a.ft_pt_count) [Month 35]
		,SUM(a.ft_pt_count*[Month 36])/SUM(a.ft_pt_count) [Month 36]
	FROM BudgetDB.dbo.calculation_table_base a
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
	LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
	WHERE a.scenario_id=@scenarioID
	GROUP BY a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
		,a.location_number,a.job_id,a.hfm_account_code,CASE WHEN LEFT(jt.job_title,5)='dummy' THEN 1 ELSE 0 END
	
	--	avg bonus
	INSERT INTO #TempAvgBonus (scenario_id, company_number, bu_number, dept_number, hfm_team_code
		,location_number, job_id, hfm_account_code, dummy_job, avg_bonus)
	SELECT a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) hfm_team_code
		,a.location_number,a.job_id,a.hfm_account_code
		,CASE WHEN LEFT(jt.job_title,5)='dummy' THEN 1 ELSE 0 END dummy_job
		,SUM(ft_pt_count*bonus_percent)/SUM(ft_pt_count) [avg_bonus]
	FROM BudgetDB.dbo.calculation_table_bonus a
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
	LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
	WHERE a.scenario_id=@scenarioID
	GROUP BY a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
		,a.location_number,a.job_id,a.hfm_account_code,CASE WHEN LEFT(jt.job_title,5)='dummy' THEN 1 ELSE 0 END
	
	--	avg commission
	INSERT INTO #TempAvgCommission (scenario_id, company_number, bu_number, dept_number, hfm_team_code
		,location_number, job_id, hfm_account_code, dummy_job, avg_commission)
	SELECT a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) hfm_team_code
		,a.location_number,a.job_id,a.hfm_account_code
		,CASE WHEN LEFT(jt.job_title,5)='dummy' THEN 1 ELSE 0 END dummy_job
		,SUM(ft_pt_count*commission_percent)/SUM(ft_pt_count) [avg_commission]
	FROM BudgetDB.dbo.calculation_table_commission a
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
	LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
	WHERE a.scenario_id=@scenarioID
	GROUP BY a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
		,a.location_number,a.job_id,a.hfm_account_code,CASE WHEN LEFT(jt.job_title,5)='dummy' THEN 1 ELSE 0 END
	
	--	cap rates
	INSERT INTO #TempCapRates (id,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6]
		,[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12]
		,[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
		,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
		,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30]
		,[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
	SELECT id,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6]
		,[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12]
		,[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
		,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
		,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30]
		,[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
	FROM BudgetDB.dbo.calculation_table_cap_rates

	--	regular salaries
	INSERT INTO #TempSalaries (company_name, location_name, bu_name, dept_name
		,team_consolidation, job_title, avg_base, avg_bonus, avg_commission, currency_code)
	SELECT c.company_name, l.location_name, b.bu_name, d.dept_name, t.team_consolidation
		,j.job_title, AVG(s.base) avg_base, AVG(s.bonus) avg_bonus
		,AVG(s.commission_target) avg_commission, s.currency_code
	FROM BudgetDB.dbo.salary_data s
	LEFT JOIN BudgetDB.dbo.companies c ON c.company_number=s.company_number
	LEFT JOIN BudgetDB.dbo.locations l ON l.location_number=s.location_number
	LEFT JOIN BudgetDB.dbo.business_units b ON b.bu_number=s.bu_number
	LEFT JOIN BudgetDB.dbo.departments d ON d.dept_number=s.dept_number
	LEFT JOIN BudgetDB.dbo.teams t ON t.hfm_team_code=s.hfm_team_code
	LEFT JOIN BudgetDB.dbo.job_titles j ON j.job_id=s.job_id
	WHERE LEFT(j.job_title,5)<>'Dummy'
	GROUP BY c.company_name, l.location_name, b.bu_name, d.dept_name
		,t.team_consolidation, j.job_title, s.currency_code

	--	dummy salaries
	INSERT INTO #TempDummySalaries (job_title, avg_base, avg_bonus
		,avg_commission, currency_code)
	SELECT j.job_title, AVG(s.base) avg_base, AVG(s.bonus) avg_bonus
		,AVG(s.commission_target) avg_commission, s.currency_code
	FROM BudgetDB.dbo.salary_data s
	LEFT JOIN BudgetDB.dbo.job_titles j ON j.job_id=s.job_id
	WHERE LEFT(j.job_title,5)='Dummy'
	GROUP BY j.job_title, s.currency_code
	
	--	live forecast data
	INSERT INTO #TempBudget (id, scenario_id, company_number, bu_number, dept_number
		,hfm_team_code, hfm_product_code, location_number, job_id
		,hfm_account_code, [description],[Month 1],[Month 2],[Month 3]
		,[Month 4],[Month 5],[Month 6],[Month 7],[Month 8]
		,[Month 9],[Month 10],[Month 11],[Month 12],[Month 13]
		,[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
		,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23]
		,[Month 24],[Month 25],[Month 26],[Month 27],[Month 28]
		,[Month 29],[Month 30],[Month 31],[Month 32],[Month 33]
		,[Month 34],[Month 35],[Month 36], category_id, workbook_id
		,sheet_name, excel_row, currency_code)
	SELECT lf.id, lf.scenario_id, lf.company_number, lf.bu_number, lf.dept_number
		,lf.hfm_team_code, lf.hfm_product_code, lf.location_number, lf.job_id
		,lf.hfm_account_code, lf.[description],lf.[Month 1],lf.[Month 2],lf.[Month 3]
		,lf.[Month 4],lf.[Month 5],lf.[Month 6],lf.[Month 7],lf.[Month 8]
		,lf.[Month 9],lf.[Month 10],lf.[Month 11],lf.[Month 12],lf.[Month 13]
		,lf.[Month 14],lf.[Month 15],lf.[Month 16],lf.[Month 17],lf.[Month 18]
		,lf.[Month 19],lf.[Month 20],lf.[Month 21],lf.[Month 22],lf.[Month 23]
		,lf.[Month 24],lf.[Month 25],lf.[Month 26],lf.[Month 27],lf.[Month 28]
		,lf.[Month 29],lf.[Month 30],lf.[Month 31],lf.[Month 32],lf.[Month 33]
		,lf.[Month 34],lf.[Month 35],lf.[Month 36], lf.category_id, lf.workbook_id
		,lf.sheet_name, lf.excel_row, lf.currency_code
	FROM BudgetDB.dbo.live_forecast lf
	JOIN BudgetDB.dbo.pl_items pl
	ON pl.hfm_account_code=lf.hfm_account_code
	--	only include records that contain Headcount that
	--	can be mapped back to salary data
	WHERE lf.job_id IS NOT NULL AND pl.pl_item='Headcount'
	AND lf.workbook_id=ISNULL(@wbID,lf.workbook_id)
END
ELSE
BEGIN	--	if frozen version, use historical tables as necessary
	--	avg base
	INSERT INTO #TempAvgBase (scenario_id, company_number, bu_number, dept_number, hfm_team_code
		,location_number, job_id, hfm_account_code, dummy_job
		,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6]
		,[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12]
		,[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
		,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
		,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30]
		,[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
	SELECT a.scenario_id, a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) hfm_team_code
		,a.location_number,a.job_id,a.hfm_account_code,CASE WHEN LEFT(jt.job_title,5)='dummy' THEN 1 ELSE 0 END dummy_job
		,SUM(a.ft_pt_count*[Month 1])/SUM(a.ft_pt_count) [Month 1]
		,SUM(a.ft_pt_count*[Month 2])/SUM(a.ft_pt_count) [Month 2]
		,SUM(a.ft_pt_count*[Month 3])/SUM(a.ft_pt_count) [Month 3]
		,SUM(a.ft_pt_count*[Month 4])/SUM(a.ft_pt_count) [Month 4]
		,SUM(a.ft_pt_count*[Month 5])/SUM(a.ft_pt_count) [Month 5]
		,SUM(a.ft_pt_count*[Month 6])/SUM(a.ft_pt_count) [Month 6]
		,SUM(a.ft_pt_count*[Month 7])/SUM(a.ft_pt_count) [Month 7]
		,SUM(a.ft_pt_count*[Month 8])/SUM(a.ft_pt_count) [Month 8]
		,SUM(a.ft_pt_count*[Month 9])/SUM(a.ft_pt_count) [Month 9]
		,SUM(a.ft_pt_count*[Month 10])/SUM(a.ft_pt_count) [Month 10]
		,SUM(a.ft_pt_count*[Month 11])/SUM(a.ft_pt_count) [Month 11]
		,SUM(a.ft_pt_count*[Month 12])/SUM(a.ft_pt_count) [Month 12]
		,SUM(a.ft_pt_count*[Month 13])/SUM(a.ft_pt_count) [Month 13]
		,SUM(a.ft_pt_count*[Month 14])/SUM(a.ft_pt_count) [Month 14]
		,SUM(a.ft_pt_count*[Month 15])/SUM(a.ft_pt_count) [Month 15]
		,SUM(a.ft_pt_count*[Month 16])/SUM(a.ft_pt_count) [Month 16]
		,SUM(a.ft_pt_count*[Month 17])/SUM(a.ft_pt_count) [Month 17]
		,SUM(a.ft_pt_count*[Month 18])/SUM(a.ft_pt_count) [Month 18]
		,SUM(a.ft_pt_count*[Month 19])/SUM(a.ft_pt_count) [Month 19]
		,SUM(a.ft_pt_count*[Month 20])/SUM(a.ft_pt_count) [Month 20]
		,SUM(a.ft_pt_count*[Month 21])/SUM(a.ft_pt_count) [Month 21]
		,SUM(a.ft_pt_count*[Month 22])/SUM(a.ft_pt_count) [Month 22]
		,SUM(a.ft_pt_count*[Month 23])/SUM(a.ft_pt_count) [Month 23]
		,SUM(a.ft_pt_count*[Month 24])/SUM(a.ft_pt_count) [Month 24]
		,SUM(a.ft_pt_count*[Month 25])/SUM(a.ft_pt_count) [Month 25]
		,SUM(a.ft_pt_count*[Month 26])/SUM(a.ft_pt_count) [Month 26]
		,SUM(a.ft_pt_count*[Month 27])/SUM(a.ft_pt_count) [Month 27]
		,SUM(a.ft_pt_count*[Month 28])/SUM(a.ft_pt_count) [Month 28]
		,SUM(a.ft_pt_count*[Month 29])/SUM(a.ft_pt_count) [Month 29]
		,SUM(a.ft_pt_count*[Month 30])/SUM(a.ft_pt_count) [Month 30]
		,SUM(a.ft_pt_count*[Month 31])/SUM(a.ft_pt_count) [Month 31]
		,SUM(a.ft_pt_count*[Month 32])/SUM(a.ft_pt_count) [Month 32]
		,SUM(a.ft_pt_count*[Month 33])/SUM(a.ft_pt_count) [Month 33]
		,SUM(a.ft_pt_count*[Month 34])/SUM(a.ft_pt_count) [Month 34]
		,SUM(a.ft_pt_count*[Month 35])/SUM(a.ft_pt_count) [Month 35]
		,SUM(a.ft_pt_count*[Month 36])/SUM(a.ft_pt_count) [Month 36]
	FROM BudgetDB.dbo.calculation_table_base a
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
	LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
	WHERE a.scenario_id=@scenarioID
	GROUP BY a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
		,a.location_number,a.job_id,a.hfm_account_code,CASE WHEN LEFT(jt.job_title,5)='dummy' THEN 1 ELSE 0 END
	
	--	avg bonus
	INSERT INTO #TempAvgBonus (scenario_id, company_number, bu_number, dept_number, hfm_team_code
		,location_number, job_id, hfm_account_code, dummy_job, avg_bonus)
	SELECT a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tmc.team_consolidation,tm.team_name,tm.hfm_team_code) hfm_team_code
		,a.location_number,a.job_id,a.hfm_account_code
		,CASE WHEN LEFT(jt.job_title,5)='dummy' THEN 1 ELSE 0 END dummy_job
		,SUM(ft_pt_count*bonus_percent)/SUM(ft_pt_count) [avg_bonus]
	FROM BudgetDB.dbo.calculation_table_bonus a
	LEFT JOIN BudgetDB.dbo.historical_table_team_consolidation tmc
	ON tmc.hfm_team_code=a.hfm_team_code
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
	LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
	WHERE a.scenario_id=@scenarioID
	GROUP BY a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tmc.team_consolidation,tm.team_name,tm.hfm_team_code)
		,a.location_number,a.job_id,a.hfm_account_code,CASE WHEN LEFT(jt.job_title,5)='dummy' THEN 1 ELSE 0 END
	
	--	avg commission
	INSERT INTO #TempAvgCommission (scenario_id, company_number, bu_number, dept_number, hfm_team_code
		,location_number, job_id, hfm_account_code, dummy_job, avg_commission)
	SELECT a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) hfm_team_code
		,a.location_number,a.job_id,a.hfm_account_code
		,CASE WHEN LEFT(jt.job_title,5)='dummy' THEN 1 ELSE 0 END dummy_job
		,SUM(ft_pt_count*commission_percent)/SUM(ft_pt_count) [avg_commission]
	FROM BudgetDB.dbo.calculation_table_commission a
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
	LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
	WHERE a.scenario_id=@scenarioID
	GROUP BY a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
		,a.location_number,a.job_id,a.hfm_account_code,CASE WHEN LEFT(jt.job_title,5)='dummy' THEN 1 ELSE 0 END
	
	--	cap rates
	INSERT INTO #TempCapRates (id,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6]
		,[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12]
		,[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
		,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
		,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30]
		,[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
	SELECT cap.id,cap.[Month 1],cap.[Month 2],cap.[Month 3],cap.[Month 4],cap.[Month 5],cap.[Month 6]
		,cap.[Month 7],cap.[Month 8],cap.[Month 9],cap.[Month 10],cap.[Month 11],cap.[Month 12]
		,cap.[Month 13],cap.[Month 14],cap.[Month 15],cap.[Month 16],cap.[Month 17],cap.[Month 18]
		,cap.[Month 19],cap.[Month 20],cap.[Month 21],cap.[Month 22],cap.[Month 23],cap.[Month 24]
		,cap.[Month 25],cap.[Month 26],cap.[Month 27],cap.[Month 28],cap.[Month 29],cap.[Month 30]
		,cap.[Month 31],cap.[Month 32],cap.[Month 33],cap.[Month 34],cap.[Month 35],cap.[Month 36]
	FROM BudgetDB.dbo.historical_table_cap_rates cap
	JOIN BudgetDB.dbo.frozen_versions fv
	ON fv.id=cap.id AND scenario_id=@scenarioID
	
	--	regular salaries
	INSERT INTO #TempSalaries (company_name, location_name, bu_name, dept_name
		,team_consolidation, job_title, avg_base, avg_bonus, avg_commission, currency_code)
	SELECT c.company_name, l.location_name, b.bu_name, d.dept_name
		,t.team_consolidation, j.job_title, AVG(s.base) avg_base, AVG(s.bonus) avg_bonus
		,AVG(s.commission_target) avg_commission, s.currency_code
	FROM BudgetDB.dbo.historical_table_salary_data s
	LEFT JOIN BudgetDB.dbo.companies c ON c.company_number=s.company_number
	LEFT JOIN BudgetDB.dbo.locations l ON l.location_number=s.location_number
	LEFT JOIN BudgetDB.dbo.business_units b ON b.bu_number=s.bu_number
	LEFT JOIN BudgetDB.dbo.departments d ON d.dept_number=s.dept_number
	LEFT JOIN BudgetDB.dbo.historical_table_team_consolidation t ON t.hfm_team_code=s.hfm_team_code
	LEFT JOIN BudgetDB.dbo.job_titles j ON j.job_id=s.job_id
	WHERE LEFT(j.job_title,5)<>'Dummy' AND s.scenario_id=@scenarioID
	GROUP BY c.company_name, l.location_name, b.bu_name, d.dept_name
		,t.team_consolidation, j.job_title, s.currency_code
	
	--	dummy salaries
	INSERT INTO #TempDummySalaries (job_title, avg_base, avg_bonus
		,avg_commission, currency_code)
	SELECT j.job_title, AVG(s.base) avg_base, AVG(s.bonus) avg_bonus
		,AVG(s.commission_target) avg_commission, s.currency_code
	FROM BudgetDB.dbo.historical_table_salary_data s
	LEFT JOIN BudgetDB.dbo.job_titles j ON j.job_id=s.job_id
	WHERE LEFT(j.job_title,5)='Dummy' AND s.scenario_id=@scenarioID
	GROUP BY j.job_title, s.currency_code

	--	frozen version data
	INSERT INTO #TempBudget (id, scenario_id, company_number, bu_number, dept_number
		,hfm_team_code, hfm_product_code, location_number, job_id
		,hfm_account_code, [description],[Month 1],[Month 2],[Month 3]
		,[Month 4],[Month 5],[Month 6],[Month 7],[Month 8]
		,[Month 9],[Month 10],[Month 11],[Month 12],[Month 13]
		,[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
		,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23]
		,[Month 24],[Month 25],[Month 26],[Month 27],[Month 28]
		,[Month 29],[Month 30],[Month 31],[Month 32],[Month 33]
		,[Month 34],[Month 35],[Month 36], workbook_id
		,sheet_name, excel_row, currency_code)
	SELECT lf.id, lf.scenario_id, lf.company_number, lf.bu_number, lf.dept_number
		,lf.hfm_team_code, lf.hfm_product_code, lf.location_number, lf.job_id
		,lf.hfm_account_code, lf.[description],lf.[Month 1],lf.[Month 2],lf.[Month 3]
		,lf.[Month 4],lf.[Month 5],lf.[Month 6],lf.[Month 7],lf.[Month 8]
		,lf.[Month 9],lf.[Month 10],lf.[Month 11],lf.[Month 12],lf.[Month 13]
		,lf.[Month 14],lf.[Month 15],lf.[Month 16],lf.[Month 17],lf.[Month 18]
		,lf.[Month 19],lf.[Month 20],lf.[Month 21],lf.[Month 22],lf.[Month 23]
		,lf.[Month 24],lf.[Month 25],lf.[Month 26],lf.[Month 27],lf.[Month 28]
		,lf.[Month 29],lf.[Month 30],lf.[Month 31],lf.[Month 32],lf.[Month 33]
		,lf.[Month 34],lf.[Month 35],lf.[Month 36], lf.workbook_id
		,lf.sheet_name, lf.excel_row, lf.local_currency
	FROM BudgetDB.dbo.frozen_versions lf
	JOIN BudgetDB.dbo.pl_items pl
	ON pl.hfm_account_code=lf.hfm_account_code
	WHERE lf.job_id IS NOT NULL AND lf.scenario_id=@scenarioID
	AND pl.pl_item='Headcount' AND lf.workbook_id=ISNULL(@wbID,lf.workbook_id)
END


--	select out all unpivoted data
SELECT u.id, sn.scenario_name, cp.company_name [Company], lc.location_name [Location], bu.bu_name [Business Unit], dp.dept_name [Department]
	,tm.team_name [Team], tm.team_consolidation [Team Consolidation], u.workbook_name [Workbook], jt.job_title [Job Title]
	,CONVERT(smalldatetime,cx.monthx,101) [Month], [Total Headcount],[Incremental Headcount]
	,CASE WHEN u.currency_code=@curr THEN 1 ELSE cr.conversion_rate END*[Base Expensed] [Base Expensed]
	,CASE WHEN u.currency_code=@curr THEN 1 ELSE cr.conversion_rate END*[Bonus Expensed] [Bonus Expensed]
	,CASE WHEN u.currency_code=@curr THEN 1 ELSE cr.conversion_rate END*[Commissions Expensed] [Commissions Expensed]
	,CASE WHEN u.currency_code=@curr THEN 1 ELSE cr.conversion_rate END*[Payroll Taxes Expensed] [Payroll Taxes Expensed]
	,CASE WHEN u.currency_code=@curr THEN 1 ELSE cr.conversion_rate END*[Base Capitalized] [Base Capitalized]
	,CASE WHEN u.currency_code=@curr THEN 1 ELSE cr.conversion_rate END*[Bonus Capitalized] [Bonus Capitalized]
	,CASE WHEN u.currency_code=@curr THEN 1 ELSE cr.conversion_rate END*[Payroll Taxes Capitalized] [Payroll Taxes Capitalized]
	,CASE WHEN u.currency_code=@curr THEN 1 ELSE cr.conversion_rate END*cx.[Avg Base] [Avg Base]
	,cx.[Avg Bonus],cx.[Avg Commissions],[Commission Attainment],[Payroll Tax Rate],[Bonus Payout],[Cap Rate]
	,CASE WHEN u.currency_code=@curr THEN 1 ELSE cr.conversion_rate END*ISNULL(sd.avg_base,sdd.avg_base) [Avg Annual Salary]
FROM (	--	select all fields necessary for calculation and unpivoting
	SELECT DISTINCT lf.scenario_id, lf.id, lf.company_number, lf.location_number, lf.bu_number, lf.dept_number
		,lf.hfm_team_code, CAST(sn.start_date AS DATE) start_date, lf.job_id, wb.workbook_name, cp.currency_code
,lf.[Month 1]
,lf.[Month 2]
,lf.[Month 3]
,lf.[Month 4]
,lf.[Month 5]
,lf.[Month 6]
,lf.[Month 7]
,lf.[Month 8]
,lf.[Month 9]
,lf.[Month 10]
,lf.[Month 11]
,lf.[Month 12]
,lf.[Month 13]
,lf.[Month 14]
,lf.[Month 15]
,lf.[Month 16]
,lf.[Month 17]
,lf.[Month 18]
,lf.[Month 19]
,lf.[Month 20]
,lf.[Month 21]
,lf.[Month 22]
,lf.[Month 23]
,lf.[Month 24]
,lf.[Month 25]
,lf.[Month 26]
,lf.[Month 27]
,lf.[Month 28]
,lf.[Month 29]
,lf.[Month 30]
,lf.[Month 31]
,lf.[Month 32]
,lf.[Month 33]
,lf.[Month 34]
,lf.[Month 35]
,lf.[Month 36]
,COALESCE(ba.[Month 1],badm.[Month 1],0) [Avg Base 1]
,COALESCE(ba.[Month 2],badm.[Month 2],0) [Avg Base 2]
,COALESCE(ba.[Month 3],badm.[Month 3],0) [Avg Base 3]
,COALESCE(ba.[Month 4],badm.[Month 4],0) [Avg Base 4]
,COALESCE(ba.[Month 5],badm.[Month 5],0) [Avg Base 5]
,COALESCE(ba.[Month 6],badm.[Month 6],0) [Avg Base 6]
,COALESCE(ba.[Month 7],badm.[Month 7],0) [Avg Base 7]
,COALESCE(ba.[Month 8],badm.[Month 8],0) [Avg Base 8]
,COALESCE(ba.[Month 9],badm.[Month 9],0) [Avg Base 9]
,COALESCE(ba.[Month 10],badm.[Month 10],0) [Avg Base 10]
,COALESCE(ba.[Month 11],badm.[Month 11],0) [Avg Base 11]
,COALESCE(ba.[Month 12],badm.[Month 12],0) [Avg Base 12]
,COALESCE(ba.[Month 13],badm.[Month 13],0) [Avg Base 13]
,COALESCE(ba.[Month 14],badm.[Month 14],0) [Avg Base 14]
,COALESCE(ba.[Month 15],badm.[Month 15],0) [Avg Base 15]
,COALESCE(ba.[Month 16],badm.[Month 16],0) [Avg Base 16]
,COALESCE(ba.[Month 17],badm.[Month 17],0) [Avg Base 17]
,COALESCE(ba.[Month 18],badm.[Month 18],0) [Avg Base 18]
,COALESCE(ba.[Month 19],badm.[Month 19],0) [Avg Base 19]
,COALESCE(ba.[Month 20],badm.[Month 20],0) [Avg Base 20]
,COALESCE(ba.[Month 21],badm.[Month 21],0) [Avg Base 21]
,COALESCE(ba.[Month 22],badm.[Month 22],0) [Avg Base 22]
,COALESCE(ba.[Month 23],badm.[Month 23],0) [Avg Base 23]
,COALESCE(ba.[Month 24],badm.[Month 24],0) [Avg Base 24]
,COALESCE(ba.[Month 25],badm.[Month 25],0) [Avg Base 25]
,COALESCE(ba.[Month 26],badm.[Month 26],0) [Avg Base 26]
,COALESCE(ba.[Month 27],badm.[Month 27],0) [Avg Base 27]
,COALESCE(ba.[Month 28],badm.[Month 28],0) [Avg Base 28]
,COALESCE(ba.[Month 29],badm.[Month 29],0) [Avg Base 29]
,COALESCE(ba.[Month 30],badm.[Month 30],0) [Avg Base 30]
,COALESCE(ba.[Month 31],badm.[Month 31],0) [Avg Base 31]
,COALESCE(ba.[Month 32],badm.[Month 32],0) [Avg Base 32]
,COALESCE(ba.[Month 33],badm.[Month 33],0) [Avg Base 33]
,COALESCE(ba.[Month 34],badm.[Month 34],0) [Avg Base 34]
,COALESCE(ba.[Month 35],badm.[Month 35],0) [Avg Base 35]
,COALESCE(ba.[Month 36],badm.[Month 36],0) [Avg Base 36]
,COALESCE(bn.avg_bonus,bndm.avg_bonus,0) [Avg Bonus]
,COALESCE(cm.avg_commission,cmdm.avg_commission,0) [Avg Commission]
,ISNULL(cma.[Month 1],0) [Attainment 1]
,ISNULL(cma.[Month 2],0) [Attainment 2]
,ISNULL(cma.[Month 3],0) [Attainment 3]
,ISNULL(cma.[Month 4],0) [Attainment 4]
,ISNULL(cma.[Month 5],0) [Attainment 5]
,ISNULL(cma.[Month 6],0) [Attainment 6]
,ISNULL(cma.[Month 7],0) [Attainment 7]
,ISNULL(cma.[Month 8],0) [Attainment 8]
,ISNULL(cma.[Month 9],0) [Attainment 9]
,ISNULL(cma.[Month 10],0) [Attainment 10]
,ISNULL(cma.[Month 11],0) [Attainment 11]
,ISNULL(cma.[Month 12],0) [Attainment 12]
,ISNULL(cma.[Month 13],0) [Attainment 13]
,ISNULL(cma.[Month 14],0) [Attainment 14]
,ISNULL(cma.[Month 15],0) [Attainment 15]
,ISNULL(cma.[Month 16],0) [Attainment 16]
,ISNULL(cma.[Month 17],0) [Attainment 17]
,ISNULL(cma.[Month 18],0) [Attainment 18]
,ISNULL(cma.[Month 19],0) [Attainment 19]
,ISNULL(cma.[Month 20],0) [Attainment 20]
,ISNULL(cma.[Month 21],0) [Attainment 21]
,ISNULL(cma.[Month 22],0) [Attainment 22]
,ISNULL(cma.[Month 23],0) [Attainment 23]
,ISNULL(cma.[Month 24],0) [Attainment 24]
,ISNULL(cma.[Month 25],0) [Attainment 25]
,ISNULL(cma.[Month 26],0) [Attainment 26]
,ISNULL(cma.[Month 27],0) [Attainment 27]
,ISNULL(cma.[Month 28],0) [Attainment 28]
,ISNULL(cma.[Month 29],0) [Attainment 29]
,ISNULL(cma.[Month 30],0) [Attainment 30]
,ISNULL(cma.[Month 31],0) [Attainment 31]
,ISNULL(cma.[Month 32],0) [Attainment 32]
,ISNULL(cma.[Month 33],0) [Attainment 33]
,ISNULL(cma.[Month 34],0) [Attainment 34]
,ISNULL(cma.[Month 35],0) [Attainment 35]
,ISNULL(cma.[Month 36],0) [Attainment 36]
,ISNULL(pt.[Month 1],dpt.[Month 1]) [PT 1]
,ISNULL(pt.[Month 2],dpt.[Month 2]) [PT 2]
,ISNULL(pt.[Month 3],dpt.[Month 3]) [PT 3]
,ISNULL(pt.[Month 4],dpt.[Month 4]) [PT 4]
,ISNULL(pt.[Month 5],dpt.[Month 5]) [PT 5]
,ISNULL(pt.[Month 6],dpt.[Month 6]) [PT 6]
,ISNULL(pt.[Month 7],dpt.[Month 7]) [PT 7]
,ISNULL(pt.[Month 8],dpt.[Month 8]) [PT 8]
,ISNULL(pt.[Month 9],dpt.[Month 9]) [PT 9]
,ISNULL(pt.[Month 10],dpt.[Month 10]) [PT 10]
,ISNULL(pt.[Month 11],dpt.[Month 11]) [PT 11]
,ISNULL(pt.[Month 12],dpt.[Month 12]) [PT 12]
,ISNULL(pt.[Month 13],dpt.[Month 13]) [PT 13]
,ISNULL(pt.[Month 14],dpt.[Month 14]) [PT 14]
,ISNULL(pt.[Month 15],dpt.[Month 15]) [PT 15]
,ISNULL(pt.[Month 16],dpt.[Month 16]) [PT 16]
,ISNULL(pt.[Month 17],dpt.[Month 17]) [PT 17]
,ISNULL(pt.[Month 18],dpt.[Month 18]) [PT 18]
,ISNULL(pt.[Month 19],dpt.[Month 19]) [PT 19]
,ISNULL(pt.[Month 20],dpt.[Month 20]) [PT 20]
,ISNULL(pt.[Month 21],dpt.[Month 21]) [PT 21]
,ISNULL(pt.[Month 22],dpt.[Month 22]) [PT 22]
,ISNULL(pt.[Month 23],dpt.[Month 23]) [PT 23]
,ISNULL(pt.[Month 24],dpt.[Month 24]) [PT 24]
,ISNULL(pt.[Month 25],dpt.[Month 25]) [PT 25]
,ISNULL(pt.[Month 26],dpt.[Month 26]) [PT 26]
,ISNULL(pt.[Month 27],dpt.[Month 27]) [PT 27]
,ISNULL(pt.[Month 28],dpt.[Month 28]) [PT 28]
,ISNULL(pt.[Month 29],dpt.[Month 29]) [PT 29]
,ISNULL(pt.[Month 30],dpt.[Month 30]) [PT 30]
,ISNULL(pt.[Month 31],dpt.[Month 31]) [PT 31]
,ISNULL(pt.[Month 32],dpt.[Month 32]) [PT 32]
,ISNULL(pt.[Month 33],dpt.[Month 33]) [PT 33]
,ISNULL(pt.[Month 34],dpt.[Month 34]) [PT 34]
,ISNULL(pt.[Month 35],dpt.[Month 35]) [PT 35]
,ISNULL(pt.[Month 36],dpt.[Month 36]) [PT 36]
,ISNULL(cap.[Month 1],0) [Cap Rate 1]
,ISNULL(cap.[Month 2],0) [Cap Rate 2]
,ISNULL(cap.[Month 3],0) [Cap Rate 3]
,ISNULL(cap.[Month 4],0) [Cap Rate 4]
,ISNULL(cap.[Month 5],0) [Cap Rate 5]
,ISNULL(cap.[Month 6],0) [Cap Rate 6]
,ISNULL(cap.[Month 7],0) [Cap Rate 7]
,ISNULL(cap.[Month 8],0) [Cap Rate 8]
,ISNULL(cap.[Month 9],0) [Cap Rate 9]
,ISNULL(cap.[Month 10],0) [Cap Rate 10]
,ISNULL(cap.[Month 11],0) [Cap Rate 11]
,ISNULL(cap.[Month 12],0) [Cap Rate 12]
,ISNULL(cap.[Month 13],0) [Cap Rate 13]
,ISNULL(cap.[Month 14],0) [Cap Rate 14]
,ISNULL(cap.[Month 15],0) [Cap Rate 15]
,ISNULL(cap.[Month 16],0) [Cap Rate 16]
,ISNULL(cap.[Month 17],0) [Cap Rate 17]
,ISNULL(cap.[Month 18],0) [Cap Rate 18]
,ISNULL(cap.[Month 19],0) [Cap Rate 19]
,ISNULL(cap.[Month 20],0) [Cap Rate 20]
,ISNULL(cap.[Month 21],0) [Cap Rate 21]
,ISNULL(cap.[Month 22],0) [Cap Rate 22]
,ISNULL(cap.[Month 23],0) [Cap Rate 23]
,ISNULL(cap.[Month 24],0) [Cap Rate 24]
,ISNULL(cap.[Month 25],0) [Cap Rate 25]
,ISNULL(cap.[Month 26],0) [Cap Rate 26]
,ISNULL(cap.[Month 27],0) [Cap Rate 27]
,ISNULL(cap.[Month 28],0) [Cap Rate 28]
,ISNULL(cap.[Month 29],0) [Cap Rate 29]
,ISNULL(cap.[Month 30],0) [Cap Rate 30]
,ISNULL(cap.[Month 31],0) [Cap Rate 31]
,ISNULL(cap.[Month 32],0) [Cap Rate 32]
,ISNULL(cap.[Month 33],0) [Cap Rate 33]
,ISNULL(cap.[Month 34],0) [Cap Rate 34]
,ISNULL(cap.[Month 35],0) [Cap Rate 35]
,ISNULL(cap.[Month 36],0) [Cap Rate 36]
,bp.[Month 1] [Bonus Payout 1]
,bp.[Month 2] [Bonus Payout 2]
,bp.[Month 3] [Bonus Payout 3]
,bp.[Month 4] [Bonus Payout 4]
,bp.[Month 5] [Bonus Payout 5]
,bp.[Month 6] [Bonus Payout 6]
,bp.[Month 7] [Bonus Payout 7]
,bp.[Month 8] [Bonus Payout 8]
,bp.[Month 9] [Bonus Payout 9]
,bp.[Month 10] [Bonus Payout 10]
,bp.[Month 11] [Bonus Payout 11]
,bp.[Month 12] [Bonus Payout 12]
,bp.[Month 13] [Bonus Payout 13]
,bp.[Month 14] [Bonus Payout 14]
,bp.[Month 15] [Bonus Payout 15]
,bp.[Month 16] [Bonus Payout 16]
,bp.[Month 17] [Bonus Payout 17]
,bp.[Month 18] [Bonus Payout 18]
,bp.[Month 19] [Bonus Payout 19]
,bp.[Month 20] [Bonus Payout 20]
,bp.[Month 21] [Bonus Payout 21]
,bp.[Month 22] [Bonus Payout 22]
,bp.[Month 23] [Bonus Payout 23]
,bp.[Month 24] [Bonus Payout 24]
,bp.[Month 25] [Bonus Payout 25]
,bp.[Month 26] [Bonus Payout 26]
,bp.[Month 27] [Bonus Payout 27]
,bp.[Month 28] [Bonus Payout 28]
,bp.[Month 29] [Bonus Payout 29]
,bp.[Month 30] [Bonus Payout 30]
,bp.[Month 31] [Bonus Payout 31]
,bp.[Month 32] [Bonus Payout 32]
,bp.[Month 33] [Bonus Payout 33]
,bp.[Month 34] [Bonus Payout 34]
,bp.[Month 35] [Bonus Payout 35]
,bp.[Month 36] [Bonus Payout 36]
	FROM #TempBudget lf
	JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=lf.scenario_id
	LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=lf.company_number
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=lf.workbook_id
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=lf.hfm_team_code
	LEFT JOIN #TempAvgBase badm ON badm.job_id=lf.job_id AND badm.scenario_id=lf.scenario_id
		AND badm.company_number=lf.company_number AND badm.dummy_job=1
	LEFT JOIN BudgetDB.dbo.historical_table_team_consolidation tmc
		ON tmc.scenario_id=@scenarioID AND tmc.hfm_team_code=lf.hfm_team_code
	LEFT JOIN #TempAvgBase ba ON ba.scenario_id=lf.scenario_id AND ba.company_number=lf.company_number
		AND ba.bu_number=lf.bu_number AND ba.dept_number=lf.dept_number 
		AND ba.hfm_team_code=COALESCE(tmc.team_consolidation,tm.team_consolidation,tm.team_name,tm.hfm_team_code)
		AND ba.location_number=lf.location_number AND ba.job_id=lf.job_id AND ba.dummy_job=0
	LEFT JOIN #TempCapRates cap ON cap.id=lf.id
	LEFT JOIN #TempAvgBonus bn ON bn.scenario_id=lf.scenario_id AND bn.company_number=lf.company_number
		AND bn.bu_number=lf.bu_number AND bn.dept_number=lf.dept_number
		AND bn.hfm_team_code=COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
		AND bn.location_number=lf.location_number AND bn.job_id=lf.job_id AND bn.dummy_job=0
	LEFT JOIN #TempAvgBonus bndm ON bndm.scenario_id=lf.scenario_id AND bndm.job_id=lf.job_id AND bndm.dummy_job=1
	LEFT JOIN BudgetDB.dbo.calculation_table_bonus_payout_pct bp ON bp.scenario_id=lf.scenario_id
	LEFT JOIN BudgetDB.dbo.calculation_table_salary_payroll_taxes pt ON pt.scenario_id=lf.scenario_id
		AND pt.company_number=lf.company_number AND pt.bu_number=lf.bu_number
	LEFT JOIN BudgetDB.dbo.calculation_table_salary_payroll_taxes dpt ON dpt.scenario_id=lf.scenario_id
		AND dpt.company_number=lf.company_number AND dpt.bu_number IS NULL
	LEFT JOIN #TempAvgCommission cm ON cm.scenario_id=lf.scenario_id AND cm.company_number=lf.company_number
		AND cm.bu_number=lf.bu_number AND cm.dept_number=lf.dept_number
		AND cm.hfm_team_code=COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
		AND cm.location_number=lf.location_number AND cm.job_id=lf.job_id AND cm.dummy_job=0
	LEFT JOIN #TempAvgCommission cmdm ON cmdm.scenario_id=lf.scenario_id AND cmdm.job_id=lf.job_id AND cmdm.dummy_job=1
	LEFT JOIN BudgetDB.dbo.calculation_table_commission_attainment cma 
		ON cma.scenario_id=lf.scenario_id AND cma.workbook_id=lf.workbook_id
) u
CROSS APPLY (	--	calculate output fields as necessary and unpivot using CROSS APPLY
	VALUES (DATEADD(m,0,start_date),[Month 1],[Month 1],[Month 1]*[Avg Base 1]*(1-[Cap Rate 1]),[Month 1]*[Avg Base 1]*[Avg Bonus]*[Bonus Payout 1]*(1-[Cap Rate 1]),[Month 1]*[Avg Base 1]*[Avg Commission]*[Attainment 1]*(1-[Cap Rate 1]),([Month 1]*[Avg Base 1]*(1-[Cap Rate 1])+[Month 1]*[Avg Base 1]*[Avg Bonus]*[Bonus Payout 1]*(1-[Cap Rate 1])+[Month 1]*[Avg Base 1]*[Avg Commission]*[Attainment 1]*(1-[Cap Rate 1]))*[PT 1],[Month 1]*[Avg Base 1]*([Cap Rate 1]),[Month 1]*[Avg Base 1]*[Avg Bonus]*[Bonus Payout 1]*([Cap Rate 1]),([Month 1]*[Avg Base 1]*([Cap Rate 1])+[Month 1]*[Avg Base 1]*[Avg Bonus]*[Bonus Payout 1]*([Cap Rate 1]))*[PT 1],[Avg Base 1],[Avg Bonus],[Avg Commission],[Attainment 1],[PT 1],[Bonus Payout 1],[Cap Rate 1]),
(DATEADD(m,1,start_date),[Month 2],[Month 2]-[Month 1],([Month 2]+[Month 1])/2*[Avg Base 2]*(1-[Cap Rate 2]),([Month 2]+[Month 1])/2*[Avg Base 2]*[Avg Bonus]*[Bonus Payout 2]*(1-[Cap Rate 2]),([Month 2]+[Month 1])/2*[Avg Base 2]*[Avg Commission]*[Attainment 2]*(1-[Cap Rate 2]),(([Month 2]+[Month 1])/2*[Avg Base 2]*(1-[Cap Rate 2])+([Month 2]+[Month 1])/2*[Avg Base 2]*[Avg Bonus]*[Bonus Payout 2]*(1-[Cap Rate 2])+([Month 2]+[Month 1])/2*[Avg Base 2]*[Avg Commission]*[Attainment 2]*(1-[Cap Rate 2]))*[PT 2],([Month 2]+[Month 1])/2*[Avg Base 2]*([Cap Rate 2]),([Month 2]+[Month 1])/2*[Avg Base 2]*[Avg Bonus]*[Bonus Payout 2]*([Cap Rate 2]),(([Month 2]+[Month 1])/2*[Avg Base 2]*([Cap Rate 2])+([Month 2]+[Month 1])/2*[Avg Base 2]*[Avg Bonus]*[Bonus Payout 2]*([Cap Rate 2]))*[PT 2],[Avg Base 2],[Avg Bonus],[Avg Commission],[Attainment 2],[PT 2],[Bonus Payout 2],[Cap Rate 2]),
(DATEADD(m,2,start_date),[Month 3],[Month 3]-[Month 2],([Month 3]+[Month 2])/2*[Avg Base 3]*(1-[Cap Rate 3]),([Month 3]+[Month 2])/2*[Avg Base 3]*[Avg Bonus]*[Bonus Payout 3]*(1-[Cap Rate 3]),([Month 3]+[Month 2])/2*[Avg Base 3]*[Avg Commission]*[Attainment 3]*(1-[Cap Rate 3]),(([Month 3]+[Month 2])/2*[Avg Base 3]*(1-[Cap Rate 3])+([Month 3]+[Month 2])/2*[Avg Base 3]*[Avg Bonus]*[Bonus Payout 3]*(1-[Cap Rate 3])+([Month 3]+[Month 2])/2*[Avg Base 3]*[Avg Commission]*[Attainment 3]*(1-[Cap Rate 3]))*[PT 3],([Month 3]+[Month 2])/2*[Avg Base 3]*([Cap Rate 3]),([Month 3]+[Month 2])/2*[Avg Base 3]*[Avg Bonus]*[Bonus Payout 3]*([Cap Rate 3]),(([Month 3]+[Month 2])/2*[Avg Base 3]*([Cap Rate 3])+([Month 3]+[Month 2])/2*[Avg Base 3]*[Avg Bonus]*[Bonus Payout 3]*([Cap Rate 3]))*[PT 3],[Avg Base 3],[Avg Bonus],[Avg Commission],[Attainment 3],[PT 3],[Bonus Payout 3],[Cap Rate 3]),
(DATEADD(m,3,start_date),[Month 4],[Month 4]-[Month 3],([Month 4]+[Month 3])/2*[Avg Base 4]*(1-[Cap Rate 4]),([Month 4]+[Month 3])/2*[Avg Base 4]*[Avg Bonus]*[Bonus Payout 4]*(1-[Cap Rate 4]),([Month 4]+[Month 3])/2*[Avg Base 4]*[Avg Commission]*[Attainment 4]*(1-[Cap Rate 4]),(([Month 4]+[Month 3])/2*[Avg Base 4]*(1-[Cap Rate 4])+([Month 4]+[Month 3])/2*[Avg Base 4]*[Avg Bonus]*[Bonus Payout 4]*(1-[Cap Rate 4])+([Month 4]+[Month 3])/2*[Avg Base 4]*[Avg Commission]*[Attainment 4]*(1-[Cap Rate 4]))*[PT 4],([Month 4]+[Month 3])/2*[Avg Base 4]*([Cap Rate 4]),([Month 4]+[Month 3])/2*[Avg Base 4]*[Avg Bonus]*[Bonus Payout 4]*([Cap Rate 4]),(([Month 4]+[Month 3])/2*[Avg Base 4]*([Cap Rate 4])+([Month 4]+[Month 3])/2*[Avg Base 4]*[Avg Bonus]*[Bonus Payout 4]*([Cap Rate 4]))*[PT 4],[Avg Base 4],[Avg Bonus],[Avg Commission],[Attainment 4],[PT 4],[Bonus Payout 4],[Cap Rate 4]),
(DATEADD(m,4,start_date),[Month 5],[Month 5]-[Month 4],([Month 5]+[Month 4])/2*[Avg Base 5]*(1-[Cap Rate 5]),([Month 5]+[Month 4])/2*[Avg Base 5]*[Avg Bonus]*[Bonus Payout 5]*(1-[Cap Rate 5]),([Month 5]+[Month 4])/2*[Avg Base 5]*[Avg Commission]*[Attainment 5]*(1-[Cap Rate 5]),(([Month 5]+[Month 4])/2*[Avg Base 5]*(1-[Cap Rate 5])+([Month 5]+[Month 4])/2*[Avg Base 5]*[Avg Bonus]*[Bonus Payout 5]*(1-[Cap Rate 5])+([Month 5]+[Month 4])/2*[Avg Base 5]*[Avg Commission]*[Attainment 5]*(1-[Cap Rate 5]))*[PT 5],([Month 5]+[Month 4])/2*[Avg Base 5]*([Cap Rate 5]),([Month 5]+[Month 4])/2*[Avg Base 5]*[Avg Bonus]*[Bonus Payout 5]*([Cap Rate 5]),(([Month 5]+[Month 4])/2*[Avg Base 5]*([Cap Rate 5])+([Month 5]+[Month 4])/2*[Avg Base 5]*[Avg Bonus]*[Bonus Payout 5]*([Cap Rate 5]))*[PT 5],[Avg Base 5],[Avg Bonus],[Avg Commission],[Attainment 5],[PT 5],[Bonus Payout 5],[Cap Rate 5]),
(DATEADD(m,5,start_date),[Month 6],[Month 6]-[Month 5],([Month 6]+[Month 5])/2*[Avg Base 6]*(1-[Cap Rate 6]),([Month 6]+[Month 5])/2*[Avg Base 6]*[Avg Bonus]*[Bonus Payout 6]*(1-[Cap Rate 6]),([Month 6]+[Month 5])/2*[Avg Base 6]*[Avg Commission]*[Attainment 6]*(1-[Cap Rate 6]),(([Month 6]+[Month 5])/2*[Avg Base 6]*(1-[Cap Rate 6])+([Month 6]+[Month 5])/2*[Avg Base 6]*[Avg Bonus]*[Bonus Payout 6]*(1-[Cap Rate 6])+([Month 6]+[Month 5])/2*[Avg Base 6]*[Avg Commission]*[Attainment 6]*(1-[Cap Rate 6]))*[PT 6],([Month 6]+[Month 5])/2*[Avg Base 6]*([Cap Rate 6]),([Month 6]+[Month 5])/2*[Avg Base 6]*[Avg Bonus]*[Bonus Payout 6]*([Cap Rate 6]),(([Month 6]+[Month 5])/2*[Avg Base 6]*([Cap Rate 6])+([Month 6]+[Month 5])/2*[Avg Base 6]*[Avg Bonus]*[Bonus Payout 6]*([Cap Rate 6]))*[PT 6],[Avg Base 6],[Avg Bonus],[Avg Commission],[Attainment 6],[PT 6],[Bonus Payout 6],[Cap Rate 6]),
(DATEADD(m,6,start_date),[Month 7],[Month 7]-[Month 6],([Month 7]+[Month 6])/2*[Avg Base 7]*(1-[Cap Rate 7]),([Month 7]+[Month 6])/2*[Avg Base 7]*[Avg Bonus]*[Bonus Payout 7]*(1-[Cap Rate 7]),([Month 7]+[Month 6])/2*[Avg Base 7]*[Avg Commission]*[Attainment 7]*(1-[Cap Rate 7]),(([Month 7]+[Month 6])/2*[Avg Base 7]*(1-[Cap Rate 7])+([Month 7]+[Month 6])/2*[Avg Base 7]*[Avg Bonus]*[Bonus Payout 7]*(1-[Cap Rate 7])+([Month 7]+[Month 6])/2*[Avg Base 7]*[Avg Commission]*[Attainment 7]*(1-[Cap Rate 7]))*[PT 7],([Month 7]+[Month 6])/2*[Avg Base 7]*([Cap Rate 7]),([Month 7]+[Month 6])/2*[Avg Base 7]*[Avg Bonus]*[Bonus Payout 7]*([Cap Rate 7]),(([Month 7]+[Month 6])/2*[Avg Base 7]*([Cap Rate 7])+([Month 7]+[Month 6])/2*[Avg Base 7]*[Avg Bonus]*[Bonus Payout 7]*([Cap Rate 7]))*[PT 7],[Avg Base 7],[Avg Bonus],[Avg Commission],[Attainment 7],[PT 7],[Bonus Payout 7],[Cap Rate 7]),
(DATEADD(m,7,start_date),[Month 8],[Month 8]-[Month 7],([Month 8]+[Month 7])/2*[Avg Base 8]*(1-[Cap Rate 8]),([Month 8]+[Month 7])/2*[Avg Base 8]*[Avg Bonus]*[Bonus Payout 8]*(1-[Cap Rate 8]),([Month 8]+[Month 7])/2*[Avg Base 8]*[Avg Commission]*[Attainment 8]*(1-[Cap Rate 8]),(([Month 8]+[Month 7])/2*[Avg Base 8]*(1-[Cap Rate 8])+([Month 8]+[Month 7])/2*[Avg Base 8]*[Avg Bonus]*[Bonus Payout 8]*(1-[Cap Rate 8])+([Month 8]+[Month 7])/2*[Avg Base 8]*[Avg Commission]*[Attainment 8]*(1-[Cap Rate 8]))*[PT 8],([Month 8]+[Month 7])/2*[Avg Base 8]*([Cap Rate 8]),([Month 8]+[Month 7])/2*[Avg Base 8]*[Avg Bonus]*[Bonus Payout 8]*([Cap Rate 8]),(([Month 8]+[Month 7])/2*[Avg Base 8]*([Cap Rate 8])+([Month 8]+[Month 7])/2*[Avg Base 8]*[Avg Bonus]*[Bonus Payout 8]*([Cap Rate 8]))*[PT 8],[Avg Base 8],[Avg Bonus],[Avg Commission],[Attainment 8],[PT 8],[Bonus Payout 8],[Cap Rate 8]),
(DATEADD(m,8,start_date),[Month 9],[Month 9]-[Month 8],([Month 9]+[Month 8])/2*[Avg Base 9]*(1-[Cap Rate 9]),([Month 9]+[Month 8])/2*[Avg Base 9]*[Avg Bonus]*[Bonus Payout 9]*(1-[Cap Rate 9]),([Month 9]+[Month 8])/2*[Avg Base 9]*[Avg Commission]*[Attainment 9]*(1-[Cap Rate 9]),(([Month 9]+[Month 8])/2*[Avg Base 9]*(1-[Cap Rate 9])+([Month 9]+[Month 8])/2*[Avg Base 9]*[Avg Bonus]*[Bonus Payout 9]*(1-[Cap Rate 9])+([Month 9]+[Month 8])/2*[Avg Base 9]*[Avg Commission]*[Attainment 9]*(1-[Cap Rate 9]))*[PT 9],([Month 9]+[Month 8])/2*[Avg Base 9]*([Cap Rate 9]),([Month 9]+[Month 8])/2*[Avg Base 9]*[Avg Bonus]*[Bonus Payout 9]*([Cap Rate 9]),(([Month 9]+[Month 8])/2*[Avg Base 9]*([Cap Rate 9])+([Month 9]+[Month 8])/2*[Avg Base 9]*[Avg Bonus]*[Bonus Payout 9]*([Cap Rate 9]))*[PT 9],[Avg Base 9],[Avg Bonus],[Avg Commission],[Attainment 9],[PT 9],[Bonus Payout 9],[Cap Rate 9]),
(DATEADD(m,9,start_date),[Month 10],[Month 10]-[Month 9],([Month 10]+[Month 9])/2*[Avg Base 10]*(1-[Cap Rate 10]),([Month 10]+[Month 9])/2*[Avg Base 10]*[Avg Bonus]*[Bonus Payout 10]*(1-[Cap Rate 10]),([Month 10]+[Month 9])/2*[Avg Base 10]*[Avg Commission]*[Attainment 10]*(1-[Cap Rate 10]),(([Month 10]+[Month 9])/2*[Avg Base 10]*(1-[Cap Rate 10])+([Month 10]+[Month 9])/2*[Avg Base 10]*[Avg Bonus]*[Bonus Payout 10]*(1-[Cap Rate 10])+([Month 10]+[Month 9])/2*[Avg Base 10]*[Avg Commission]*[Attainment 10]*(1-[Cap Rate 10]))*[PT 10],([Month 10]+[Month 9])/2*[Avg Base 10]*([Cap Rate 10]),([Month 10]+[Month 9])/2*[Avg Base 10]*[Avg Bonus]*[Bonus Payout 10]*([Cap Rate 10]),(([Month 10]+[Month 9])/2*[Avg Base 10]*([Cap Rate 10])+([Month 10]+[Month 9])/2*[Avg Base 10]*[Avg Bonus]*[Bonus Payout 10]*([Cap Rate 10]))*[PT 10],[Avg Base 10],[Avg Bonus],[Avg Commission],[Attainment 10],[PT 10],[Bonus Payout 10],[Cap Rate 10]),
(DATEADD(m,10,start_date),[Month 11],[Month 11]-[Month 10],([Month 11]+[Month 10])/2*[Avg Base 11]*(1-[Cap Rate 11]),([Month 11]+[Month 10])/2*[Avg Base 11]*[Avg Bonus]*[Bonus Payout 11]*(1-[Cap Rate 11]),([Month 11]+[Month 10])/2*[Avg Base 11]*[Avg Commission]*[Attainment 11]*(1-[Cap Rate 11]),(([Month 11]+[Month 10])/2*[Avg Base 11]*(1-[Cap Rate 11])+([Month 11]+[Month 10])/2*[Avg Base 11]*[Avg Bonus]*[Bonus Payout 11]*(1-[Cap Rate 11])+([Month 11]+[Month 10])/2*[Avg Base 11]*[Avg Commission]*[Attainment 11]*(1-[Cap Rate 11]))*[PT 11],([Month 11]+[Month 10])/2*[Avg Base 11]*([Cap Rate 11]),([Month 11]+[Month 10])/2*[Avg Base 11]*[Avg Bonus]*[Bonus Payout 11]*([Cap Rate 11]),(([Month 11]+[Month 10])/2*[Avg Base 11]*([Cap Rate 11])+([Month 11]+[Month 10])/2*[Avg Base 11]*[Avg Bonus]*[Bonus Payout 11]*([Cap Rate 11]))*[PT 11],[Avg Base 11],[Avg Bonus],[Avg Commission],[Attainment 11],[PT 11],[Bonus Payout 11],[Cap Rate 11]),
(DATEADD(m,11,start_date),[Month 12],[Month 12]-[Month 11],([Month 12]+[Month 11])/2*[Avg Base 12]*(1-[Cap Rate 12]),([Month 12]+[Month 11])/2*[Avg Base 12]*[Avg Bonus]*[Bonus Payout 12]*(1-[Cap Rate 12]),([Month 12]+[Month 11])/2*[Avg Base 12]*[Avg Commission]*[Attainment 12]*(1-[Cap Rate 12]),(([Month 12]+[Month 11])/2*[Avg Base 12]*(1-[Cap Rate 12])+([Month 12]+[Month 11])/2*[Avg Base 12]*[Avg Bonus]*[Bonus Payout 12]*(1-[Cap Rate 12])+([Month 12]+[Month 11])/2*[Avg Base 12]*[Avg Commission]*[Attainment 12]*(1-[Cap Rate 12]))*[PT 12],([Month 12]+[Month 11])/2*[Avg Base 12]*([Cap Rate 12]),([Month 12]+[Month 11])/2*[Avg Base 12]*[Avg Bonus]*[Bonus Payout 12]*([Cap Rate 12]),(([Month 12]+[Month 11])/2*[Avg Base 12]*([Cap Rate 12])+([Month 12]+[Month 11])/2*[Avg Base 12]*[Avg Bonus]*[Bonus Payout 12]*([Cap Rate 12]))*[PT 12],[Avg Base 12],[Avg Bonus],[Avg Commission],[Attainment 12],[PT 12],[Bonus Payout 12],[Cap Rate 12]),
(DATEADD(m,12,start_date),[Month 13],[Month 13]-[Month 12],([Month 13]+[Month 12])/2*[Avg Base 13]*(1-[Cap Rate 13]),([Month 13]+[Month 12])/2*[Avg Base 13]*[Avg Bonus]*[Bonus Payout 13]*(1-[Cap Rate 13]),([Month 13]+[Month 12])/2*[Avg Base 13]*[Avg Commission]*[Attainment 13]*(1-[Cap Rate 13]),(([Month 13]+[Month 12])/2*[Avg Base 13]*(1-[Cap Rate 13])+([Month 13]+[Month 12])/2*[Avg Base 13]*[Avg Bonus]*[Bonus Payout 13]*(1-[Cap Rate 13])+([Month 13]+[Month 12])/2*[Avg Base 13]*[Avg Commission]*[Attainment 13]*(1-[Cap Rate 13]))*[PT 13],([Month 13]+[Month 12])/2*[Avg Base 13]*([Cap Rate 13]),([Month 13]+[Month 12])/2*[Avg Base 13]*[Avg Bonus]*[Bonus Payout 13]*([Cap Rate 13]),(([Month 13]+[Month 12])/2*[Avg Base 13]*([Cap Rate 13])+([Month 13]+[Month 12])/2*[Avg Base 13]*[Avg Bonus]*[Bonus Payout 13]*([Cap Rate 13]))*[PT 13],[Avg Base 13],[Avg Bonus],[Avg Commission],[Attainment 13],[PT 13],[Bonus Payout 13],[Cap Rate 13]),
(DATEADD(m,13,start_date),[Month 14],[Month 14]-[Month 13],([Month 14]+[Month 13])/2*[Avg Base 14]*(1-[Cap Rate 14]),([Month 14]+[Month 13])/2*[Avg Base 14]*[Avg Bonus]*[Bonus Payout 14]*(1-[Cap Rate 14]),([Month 14]+[Month 13])/2*[Avg Base 14]*[Avg Commission]*[Attainment 14]*(1-[Cap Rate 14]),(([Month 14]+[Month 13])/2*[Avg Base 14]*(1-[Cap Rate 14])+([Month 14]+[Month 13])/2*[Avg Base 14]*[Avg Bonus]*[Bonus Payout 14]*(1-[Cap Rate 14])+([Month 14]+[Month 13])/2*[Avg Base 14]*[Avg Commission]*[Attainment 14]*(1-[Cap Rate 14]))*[PT 14],([Month 14]+[Month 13])/2*[Avg Base 14]*([Cap Rate 14]),([Month 14]+[Month 13])/2*[Avg Base 14]*[Avg Bonus]*[Bonus Payout 14]*([Cap Rate 14]),(([Month 14]+[Month 13])/2*[Avg Base 14]*([Cap Rate 14])+([Month 14]+[Month 13])/2*[Avg Base 14]*[Avg Bonus]*[Bonus Payout 14]*([Cap Rate 14]))*[PT 14],[Avg Base 14],[Avg Bonus],[Avg Commission],[Attainment 14],[PT 14],[Bonus Payout 14],[Cap Rate 14]),
(DATEADD(m,14,start_date),[Month 15],[Month 15]-[Month 14],([Month 15]+[Month 14])/2*[Avg Base 15]*(1-[Cap Rate 15]),([Month 15]+[Month 14])/2*[Avg Base 15]*[Avg Bonus]*[Bonus Payout 15]*(1-[Cap Rate 15]),([Month 15]+[Month 14])/2*[Avg Base 15]*[Avg Commission]*[Attainment 15]*(1-[Cap Rate 15]),(([Month 15]+[Month 14])/2*[Avg Base 15]*(1-[Cap Rate 15])+([Month 15]+[Month 14])/2*[Avg Base 15]*[Avg Bonus]*[Bonus Payout 15]*(1-[Cap Rate 15])+([Month 15]+[Month 14])/2*[Avg Base 15]*[Avg Commission]*[Attainment 15]*(1-[Cap Rate 15]))*[PT 15],([Month 15]+[Month 14])/2*[Avg Base 15]*([Cap Rate 15]),([Month 15]+[Month 14])/2*[Avg Base 15]*[Avg Bonus]*[Bonus Payout 15]*([Cap Rate 15]),(([Month 15]+[Month 14])/2*[Avg Base 15]*([Cap Rate 15])+([Month 15]+[Month 14])/2*[Avg Base 15]*[Avg Bonus]*[Bonus Payout 15]*([Cap Rate 15]))*[PT 15],[Avg Base 15],[Avg Bonus],[Avg Commission],[Attainment 15],[PT 15],[Bonus Payout 15],[Cap Rate 15]),
(DATEADD(m,15,start_date),[Month 16],[Month 16]-[Month 15],([Month 16]+[Month 15])/2*[Avg Base 16]*(1-[Cap Rate 16]),([Month 16]+[Month 15])/2*[Avg Base 16]*[Avg Bonus]*[Bonus Payout 16]*(1-[Cap Rate 16]),([Month 16]+[Month 15])/2*[Avg Base 16]*[Avg Commission]*[Attainment 16]*(1-[Cap Rate 16]),(([Month 16]+[Month 15])/2*[Avg Base 16]*(1-[Cap Rate 16])+([Month 16]+[Month 15])/2*[Avg Base 16]*[Avg Bonus]*[Bonus Payout 16]*(1-[Cap Rate 16])+([Month 16]+[Month 15])/2*[Avg Base 16]*[Avg Commission]*[Attainment 16]*(1-[Cap Rate 16]))*[PT 16],([Month 16]+[Month 15])/2*[Avg Base 16]*([Cap Rate 16]),([Month 16]+[Month 15])/2*[Avg Base 16]*[Avg Bonus]*[Bonus Payout 16]*([Cap Rate 16]),(([Month 16]+[Month 15])/2*[Avg Base 16]*([Cap Rate 16])+([Month 16]+[Month 15])/2*[Avg Base 16]*[Avg Bonus]*[Bonus Payout 16]*([Cap Rate 16]))*[PT 16],[Avg Base 16],[Avg Bonus],[Avg Commission],[Attainment 16],[PT 16],[Bonus Payout 16],[Cap Rate 16]),
(DATEADD(m,16,start_date),[Month 17],[Month 17]-[Month 16],([Month 17]+[Month 16])/2*[Avg Base 17]*(1-[Cap Rate 17]),([Month 17]+[Month 16])/2*[Avg Base 17]*[Avg Bonus]*[Bonus Payout 17]*(1-[Cap Rate 17]),([Month 17]+[Month 16])/2*[Avg Base 17]*[Avg Commission]*[Attainment 17]*(1-[Cap Rate 17]),(([Month 17]+[Month 16])/2*[Avg Base 17]*(1-[Cap Rate 17])+([Month 17]+[Month 16])/2*[Avg Base 17]*[Avg Bonus]*[Bonus Payout 17]*(1-[Cap Rate 17])+([Month 17]+[Month 16])/2*[Avg Base 17]*[Avg Commission]*[Attainment 17]*(1-[Cap Rate 17]))*[PT 17],([Month 17]+[Month 16])/2*[Avg Base 17]*([Cap Rate 17]),([Month 17]+[Month 16])/2*[Avg Base 17]*[Avg Bonus]*[Bonus Payout 17]*([Cap Rate 17]),(([Month 17]+[Month 16])/2*[Avg Base 17]*([Cap Rate 17])+([Month 17]+[Month 16])/2*[Avg Base 17]*[Avg Bonus]*[Bonus Payout 17]*([Cap Rate 17]))*[PT 17],[Avg Base 17],[Avg Bonus],[Avg Commission],[Attainment 17],[PT 17],[Bonus Payout 17],[Cap Rate 17]),
(DATEADD(m,17,start_date),[Month 18],[Month 18]-[Month 17],([Month 18]+[Month 17])/2*[Avg Base 18]*(1-[Cap Rate 18]),([Month 18]+[Month 17])/2*[Avg Base 18]*[Avg Bonus]*[Bonus Payout 18]*(1-[Cap Rate 18]),([Month 18]+[Month 17])/2*[Avg Base 18]*[Avg Commission]*[Attainment 18]*(1-[Cap Rate 18]),(([Month 18]+[Month 17])/2*[Avg Base 18]*(1-[Cap Rate 18])+([Month 18]+[Month 17])/2*[Avg Base 18]*[Avg Bonus]*[Bonus Payout 18]*(1-[Cap Rate 18])+([Month 18]+[Month 17])/2*[Avg Base 18]*[Avg Commission]*[Attainment 18]*(1-[Cap Rate 18]))*[PT 18],([Month 18]+[Month 17])/2*[Avg Base 18]*([Cap Rate 18]),([Month 18]+[Month 17])/2*[Avg Base 18]*[Avg Bonus]*[Bonus Payout 18]*([Cap Rate 18]),(([Month 18]+[Month 17])/2*[Avg Base 18]*([Cap Rate 18])+([Month 18]+[Month 17])/2*[Avg Base 18]*[Avg Bonus]*[Bonus Payout 18]*([Cap Rate 18]))*[PT 18],[Avg Base 18],[Avg Bonus],[Avg Commission],[Attainment 18],[PT 18],[Bonus Payout 18],[Cap Rate 18]),
(DATEADD(m,18,start_date),[Month 19],[Month 19]-[Month 18],([Month 19]+[Month 18])/2*[Avg Base 19]*(1-[Cap Rate 19]),([Month 19]+[Month 18])/2*[Avg Base 19]*[Avg Bonus]*[Bonus Payout 19]*(1-[Cap Rate 19]),([Month 19]+[Month 18])/2*[Avg Base 19]*[Avg Commission]*[Attainment 19]*(1-[Cap Rate 19]),(([Month 19]+[Month 18])/2*[Avg Base 19]*(1-[Cap Rate 19])+([Month 19]+[Month 18])/2*[Avg Base 19]*[Avg Bonus]*[Bonus Payout 19]*(1-[Cap Rate 19])+([Month 19]+[Month 18])/2*[Avg Base 19]*[Avg Commission]*[Attainment 19]*(1-[Cap Rate 19]))*[PT 19],([Month 19]+[Month 18])/2*[Avg Base 19]*([Cap Rate 19]),([Month 19]+[Month 18])/2*[Avg Base 19]*[Avg Bonus]*[Bonus Payout 19]*([Cap Rate 19]),(([Month 19]+[Month 18])/2*[Avg Base 19]*([Cap Rate 19])+([Month 19]+[Month 18])/2*[Avg Base 19]*[Avg Bonus]*[Bonus Payout 19]*([Cap Rate 19]))*[PT 19],[Avg Base 19],[Avg Bonus],[Avg Commission],[Attainment 19],[PT 19],[Bonus Payout 19],[Cap Rate 19]),
(DATEADD(m,19,start_date),[Month 20],[Month 20]-[Month 19],([Month 20]+[Month 19])/2*[Avg Base 20]*(1-[Cap Rate 20]),([Month 20]+[Month 19])/2*[Avg Base 20]*[Avg Bonus]*[Bonus Payout 20]*(1-[Cap Rate 20]),([Month 20]+[Month 19])/2*[Avg Base 20]*[Avg Commission]*[Attainment 20]*(1-[Cap Rate 20]),(([Month 20]+[Month 19])/2*[Avg Base 20]*(1-[Cap Rate 20])+([Month 20]+[Month 19])/2*[Avg Base 20]*[Avg Bonus]*[Bonus Payout 20]*(1-[Cap Rate 20])+([Month 20]+[Month 19])/2*[Avg Base 20]*[Avg Commission]*[Attainment 20]*(1-[Cap Rate 20]))*[PT 20],([Month 20]+[Month 19])/2*[Avg Base 20]*([Cap Rate 20]),([Month 20]+[Month 19])/2*[Avg Base 20]*[Avg Bonus]*[Bonus Payout 20]*([Cap Rate 20]),(([Month 20]+[Month 19])/2*[Avg Base 20]*([Cap Rate 20])+([Month 20]+[Month 19])/2*[Avg Base 20]*[Avg Bonus]*[Bonus Payout 20]*([Cap Rate 20]))*[PT 20],[Avg Base 20],[Avg Bonus],[Avg Commission],[Attainment 20],[PT 20],[Bonus Payout 20],[Cap Rate 20]),
(DATEADD(m,20,start_date),[Month 21],[Month 21]-[Month 20],([Month 21]+[Month 20])/2*[Avg Base 21]*(1-[Cap Rate 21]),([Month 21]+[Month 20])/2*[Avg Base 21]*[Avg Bonus]*[Bonus Payout 21]*(1-[Cap Rate 21]),([Month 21]+[Month 20])/2*[Avg Base 21]*[Avg Commission]*[Attainment 21]*(1-[Cap Rate 21]),(([Month 21]+[Month 20])/2*[Avg Base 21]*(1-[Cap Rate 21])+([Month 21]+[Month 20])/2*[Avg Base 21]*[Avg Bonus]*[Bonus Payout 21]*(1-[Cap Rate 21])+([Month 21]+[Month 20])/2*[Avg Base 21]*[Avg Commission]*[Attainment 21]*(1-[Cap Rate 21]))*[PT 21],([Month 21]+[Month 20])/2*[Avg Base 21]*([Cap Rate 21]),([Month 21]+[Month 20])/2*[Avg Base 21]*[Avg Bonus]*[Bonus Payout 21]*([Cap Rate 21]),(([Month 21]+[Month 20])/2*[Avg Base 21]*([Cap Rate 21])+([Month 21]+[Month 20])/2*[Avg Base 21]*[Avg Bonus]*[Bonus Payout 21]*([Cap Rate 21]))*[PT 21],[Avg Base 21],[Avg Bonus],[Avg Commission],[Attainment 21],[PT 21],[Bonus Payout 21],[Cap Rate 21]),
(DATEADD(m,21,start_date),[Month 22],[Month 22]-[Month 21],([Month 22]+[Month 21])/2*[Avg Base 22]*(1-[Cap Rate 22]),([Month 22]+[Month 21])/2*[Avg Base 22]*[Avg Bonus]*[Bonus Payout 22]*(1-[Cap Rate 22]),([Month 22]+[Month 21])/2*[Avg Base 22]*[Avg Commission]*[Attainment 22]*(1-[Cap Rate 22]),(([Month 22]+[Month 21])/2*[Avg Base 22]*(1-[Cap Rate 22])+([Month 22]+[Month 21])/2*[Avg Base 22]*[Avg Bonus]*[Bonus Payout 22]*(1-[Cap Rate 22])+([Month 22]+[Month 21])/2*[Avg Base 22]*[Avg Commission]*[Attainment 22]*(1-[Cap Rate 22]))*[PT 22],([Month 22]+[Month 21])/2*[Avg Base 22]*([Cap Rate 22]),([Month 22]+[Month 21])/2*[Avg Base 22]*[Avg Bonus]*[Bonus Payout 22]*([Cap Rate 22]),(([Month 22]+[Month 21])/2*[Avg Base 22]*([Cap Rate 22])+([Month 22]+[Month 21])/2*[Avg Base 22]*[Avg Bonus]*[Bonus Payout 22]*([Cap Rate 22]))*[PT 22],[Avg Base 22],[Avg Bonus],[Avg Commission],[Attainment 22],[PT 22],[Bonus Payout 22],[Cap Rate 22]),
(DATEADD(m,22,start_date),[Month 23],[Month 23]-[Month 22],([Month 23]+[Month 22])/2*[Avg Base 23]*(1-[Cap Rate 23]),([Month 23]+[Month 22])/2*[Avg Base 23]*[Avg Bonus]*[Bonus Payout 23]*(1-[Cap Rate 23]),([Month 23]+[Month 22])/2*[Avg Base 23]*[Avg Commission]*[Attainment 23]*(1-[Cap Rate 23]),(([Month 23]+[Month 22])/2*[Avg Base 23]*(1-[Cap Rate 23])+([Month 23]+[Month 22])/2*[Avg Base 23]*[Avg Bonus]*[Bonus Payout 23]*(1-[Cap Rate 23])+([Month 23]+[Month 22])/2*[Avg Base 23]*[Avg Commission]*[Attainment 23]*(1-[Cap Rate 23]))*[PT 23],([Month 23]+[Month 22])/2*[Avg Base 23]*([Cap Rate 23]),([Month 23]+[Month 22])/2*[Avg Base 23]*[Avg Bonus]*[Bonus Payout 23]*([Cap Rate 23]),(([Month 23]+[Month 22])/2*[Avg Base 23]*([Cap Rate 23])+([Month 23]+[Month 22])/2*[Avg Base 23]*[Avg Bonus]*[Bonus Payout 23]*([Cap Rate 23]))*[PT 23],[Avg Base 23],[Avg Bonus],[Avg Commission],[Attainment 23],[PT 23],[Bonus Payout 23],[Cap Rate 23]),
(DATEADD(m,23,start_date),[Month 24],[Month 24]-[Month 23],([Month 24]+[Month 23])/2*[Avg Base 24]*(1-[Cap Rate 24]),([Month 24]+[Month 23])/2*[Avg Base 24]*[Avg Bonus]*[Bonus Payout 24]*(1-[Cap Rate 24]),([Month 24]+[Month 23])/2*[Avg Base 24]*[Avg Commission]*[Attainment 24]*(1-[Cap Rate 24]),(([Month 24]+[Month 23])/2*[Avg Base 24]*(1-[Cap Rate 24])+([Month 24]+[Month 23])/2*[Avg Base 24]*[Avg Bonus]*[Bonus Payout 24]*(1-[Cap Rate 24])+([Month 24]+[Month 23])/2*[Avg Base 24]*[Avg Commission]*[Attainment 24]*(1-[Cap Rate 24]))*[PT 24],([Month 24]+[Month 23])/2*[Avg Base 24]*([Cap Rate 24]),([Month 24]+[Month 23])/2*[Avg Base 24]*[Avg Bonus]*[Bonus Payout 24]*([Cap Rate 24]),(([Month 24]+[Month 23])/2*[Avg Base 24]*([Cap Rate 24])+([Month 24]+[Month 23])/2*[Avg Base 24]*[Avg Bonus]*[Bonus Payout 24]*([Cap Rate 24]))*[PT 24],[Avg Base 24],[Avg Bonus],[Avg Commission],[Attainment 24],[PT 24],[Bonus Payout 24],[Cap Rate 24]),
(DATEADD(m,24,start_date),[Month 25],[Month 25]-[Month 24],([Month 25]+[Month 24])/2*[Avg Base 25]*(1-[Cap Rate 25]),([Month 25]+[Month 24])/2*[Avg Base 25]*[Avg Bonus]*[Bonus Payout 25]*(1-[Cap Rate 25]),([Month 25]+[Month 24])/2*[Avg Base 25]*[Avg Commission]*[Attainment 25]*(1-[Cap Rate 25]),(([Month 25]+[Month 24])/2*[Avg Base 25]*(1-[Cap Rate 25])+([Month 25]+[Month 24])/2*[Avg Base 25]*[Avg Bonus]*[Bonus Payout 25]*(1-[Cap Rate 25])+([Month 25]+[Month 24])/2*[Avg Base 25]*[Avg Commission]*[Attainment 25]*(1-[Cap Rate 25]))*[PT 25],([Month 25]+[Month 24])/2*[Avg Base 25]*([Cap Rate 25]),([Month 25]+[Month 24])/2*[Avg Base 25]*[Avg Bonus]*[Bonus Payout 25]*([Cap Rate 25]),(([Month 25]+[Month 24])/2*[Avg Base 25]*([Cap Rate 25])+([Month 25]+[Month 24])/2*[Avg Base 25]*[Avg Bonus]*[Bonus Payout 25]*([Cap Rate 25]))*[PT 25],[Avg Base 25],[Avg Bonus],[Avg Commission],[Attainment 25],[PT 25],[Bonus Payout 25],[Cap Rate 25]),
(DATEADD(m,25,start_date),[Month 26],[Month 26]-[Month 25],([Month 26]+[Month 25])/2*[Avg Base 26]*(1-[Cap Rate 26]),([Month 26]+[Month 25])/2*[Avg Base 26]*[Avg Bonus]*[Bonus Payout 26]*(1-[Cap Rate 26]),([Month 26]+[Month 25])/2*[Avg Base 26]*[Avg Commission]*[Attainment 26]*(1-[Cap Rate 26]),(([Month 26]+[Month 25])/2*[Avg Base 26]*(1-[Cap Rate 26])+([Month 26]+[Month 25])/2*[Avg Base 26]*[Avg Bonus]*[Bonus Payout 26]*(1-[Cap Rate 26])+([Month 26]+[Month 25])/2*[Avg Base 26]*[Avg Commission]*[Attainment 26]*(1-[Cap Rate 26]))*[PT 26],([Month 26]+[Month 25])/2*[Avg Base 26]*([Cap Rate 26]),([Month 26]+[Month 25])/2*[Avg Base 26]*[Avg Bonus]*[Bonus Payout 26]*([Cap Rate 26]),(([Month 26]+[Month 25])/2*[Avg Base 26]*([Cap Rate 26])+([Month 26]+[Month 25])/2*[Avg Base 26]*[Avg Bonus]*[Bonus Payout 26]*([Cap Rate 26]))*[PT 26],[Avg Base 26],[Avg Bonus],[Avg Commission],[Attainment 26],[PT 26],[Bonus Payout 26],[Cap Rate 26]),
(DATEADD(m,26,start_date),[Month 27],[Month 27]-[Month 26],([Month 27]+[Month 26])/2*[Avg Base 27]*(1-[Cap Rate 27]),([Month 27]+[Month 26])/2*[Avg Base 27]*[Avg Bonus]*[Bonus Payout 27]*(1-[Cap Rate 27]),([Month 27]+[Month 26])/2*[Avg Base 27]*[Avg Commission]*[Attainment 27]*(1-[Cap Rate 27]),(([Month 27]+[Month 26])/2*[Avg Base 27]*(1-[Cap Rate 27])+([Month 27]+[Month 26])/2*[Avg Base 27]*[Avg Bonus]*[Bonus Payout 27]*(1-[Cap Rate 27])+([Month 27]+[Month 26])/2*[Avg Base 27]*[Avg Commission]*[Attainment 27]*(1-[Cap Rate 27]))*[PT 27],([Month 27]+[Month 26])/2*[Avg Base 27]*([Cap Rate 27]),([Month 27]+[Month 26])/2*[Avg Base 27]*[Avg Bonus]*[Bonus Payout 27]*([Cap Rate 27]),(([Month 27]+[Month 26])/2*[Avg Base 27]*([Cap Rate 27])+([Month 27]+[Month 26])/2*[Avg Base 27]*[Avg Bonus]*[Bonus Payout 27]*([Cap Rate 27]))*[PT 27],[Avg Base 27],[Avg Bonus],[Avg Commission],[Attainment 27],[PT 27],[Bonus Payout 27],[Cap Rate 27]),
(DATEADD(m,27,start_date),[Month 28],[Month 28]-[Month 27],([Month 28]+[Month 27])/2*[Avg Base 28]*(1-[Cap Rate 28]),([Month 28]+[Month 27])/2*[Avg Base 28]*[Avg Bonus]*[Bonus Payout 28]*(1-[Cap Rate 28]),([Month 28]+[Month 27])/2*[Avg Base 28]*[Avg Commission]*[Attainment 28]*(1-[Cap Rate 28]),(([Month 28]+[Month 27])/2*[Avg Base 28]*(1-[Cap Rate 28])+([Month 28]+[Month 27])/2*[Avg Base 28]*[Avg Bonus]*[Bonus Payout 28]*(1-[Cap Rate 28])+([Month 28]+[Month 27])/2*[Avg Base 28]*[Avg Commission]*[Attainment 28]*(1-[Cap Rate 28]))*[PT 28],([Month 28]+[Month 27])/2*[Avg Base 28]*([Cap Rate 28]),([Month 28]+[Month 27])/2*[Avg Base 28]*[Avg Bonus]*[Bonus Payout 28]*([Cap Rate 28]),(([Month 28]+[Month 27])/2*[Avg Base 28]*([Cap Rate 28])+([Month 28]+[Month 27])/2*[Avg Base 28]*[Avg Bonus]*[Bonus Payout 28]*([Cap Rate 28]))*[PT 28],[Avg Base 28],[Avg Bonus],[Avg Commission],[Attainment 28],[PT 28],[Bonus Payout 28],[Cap Rate 28]),
(DATEADD(m,28,start_date),[Month 29],[Month 29]-[Month 28],([Month 29]+[Month 28])/2*[Avg Base 29]*(1-[Cap Rate 29]),([Month 29]+[Month 28])/2*[Avg Base 29]*[Avg Bonus]*[Bonus Payout 29]*(1-[Cap Rate 29]),([Month 29]+[Month 28])/2*[Avg Base 29]*[Avg Commission]*[Attainment 29]*(1-[Cap Rate 29]),(([Month 29]+[Month 28])/2*[Avg Base 29]*(1-[Cap Rate 29])+([Month 29]+[Month 28])/2*[Avg Base 29]*[Avg Bonus]*[Bonus Payout 29]*(1-[Cap Rate 29])+([Month 29]+[Month 28])/2*[Avg Base 29]*[Avg Commission]*[Attainment 29]*(1-[Cap Rate 29]))*[PT 29],([Month 29]+[Month 28])/2*[Avg Base 29]*([Cap Rate 29]),([Month 29]+[Month 28])/2*[Avg Base 29]*[Avg Bonus]*[Bonus Payout 29]*([Cap Rate 29]),(([Month 29]+[Month 28])/2*[Avg Base 29]*([Cap Rate 29])+([Month 29]+[Month 28])/2*[Avg Base 29]*[Avg Bonus]*[Bonus Payout 29]*([Cap Rate 29]))*[PT 29],[Avg Base 29],[Avg Bonus],[Avg Commission],[Attainment 29],[PT 29],[Bonus Payout 29],[Cap Rate 29]),
(DATEADD(m,29,start_date),[Month 30],[Month 30]-[Month 29],([Month 30]+[Month 29])/2*[Avg Base 30]*(1-[Cap Rate 30]),([Month 30]+[Month 29])/2*[Avg Base 30]*[Avg Bonus]*[Bonus Payout 30]*(1-[Cap Rate 30]),([Month 30]+[Month 29])/2*[Avg Base 30]*[Avg Commission]*[Attainment 30]*(1-[Cap Rate 30]),(([Month 30]+[Month 29])/2*[Avg Base 30]*(1-[Cap Rate 30])+([Month 30]+[Month 29])/2*[Avg Base 30]*[Avg Bonus]*[Bonus Payout 30]*(1-[Cap Rate 30])+([Month 30]+[Month 29])/2*[Avg Base 30]*[Avg Commission]*[Attainment 30]*(1-[Cap Rate 30]))*[PT 30],([Month 30]+[Month 29])/2*[Avg Base 30]*([Cap Rate 30]),([Month 30]+[Month 29])/2*[Avg Base 30]*[Avg Bonus]*[Bonus Payout 30]*([Cap Rate 30]),(([Month 30]+[Month 29])/2*[Avg Base 30]*([Cap Rate 30])+([Month 30]+[Month 29])/2*[Avg Base 30]*[Avg Bonus]*[Bonus Payout 30]*([Cap Rate 30]))*[PT 30],[Avg Base 30],[Avg Bonus],[Avg Commission],[Attainment 30],[PT 30],[Bonus Payout 30],[Cap Rate 30]),
(DATEADD(m,30,start_date),[Month 31],[Month 31]-[Month 30],([Month 31]+[Month 30])/2*[Avg Base 31]*(1-[Cap Rate 31]),([Month 31]+[Month 30])/2*[Avg Base 31]*[Avg Bonus]*[Bonus Payout 31]*(1-[Cap Rate 31]),([Month 31]+[Month 30])/2*[Avg Base 31]*[Avg Commission]*[Attainment 31]*(1-[Cap Rate 31]),(([Month 31]+[Month 30])/2*[Avg Base 31]*(1-[Cap Rate 31])+([Month 31]+[Month 30])/2*[Avg Base 31]*[Avg Bonus]*[Bonus Payout 31]*(1-[Cap Rate 31])+([Month 31]+[Month 30])/2*[Avg Base 31]*[Avg Commission]*[Attainment 31]*(1-[Cap Rate 31]))*[PT 31],([Month 31]+[Month 30])/2*[Avg Base 31]*([Cap Rate 31]),([Month 31]+[Month 30])/2*[Avg Base 31]*[Avg Bonus]*[Bonus Payout 31]*([Cap Rate 31]),(([Month 31]+[Month 30])/2*[Avg Base 31]*([Cap Rate 31])+([Month 31]+[Month 30])/2*[Avg Base 31]*[Avg Bonus]*[Bonus Payout 31]*([Cap Rate 31]))*[PT 31],[Avg Base 31],[Avg Bonus],[Avg Commission],[Attainment 31],[PT 31],[Bonus Payout 31],[Cap Rate 31]),
(DATEADD(m,31,start_date),[Month 32],[Month 32]-[Month 31],([Month 32]+[Month 31])/2*[Avg Base 32]*(1-[Cap Rate 32]),([Month 32]+[Month 31])/2*[Avg Base 32]*[Avg Bonus]*[Bonus Payout 32]*(1-[Cap Rate 32]),([Month 32]+[Month 31])/2*[Avg Base 32]*[Avg Commission]*[Attainment 32]*(1-[Cap Rate 32]),(([Month 32]+[Month 31])/2*[Avg Base 32]*(1-[Cap Rate 32])+([Month 32]+[Month 31])/2*[Avg Base 32]*[Avg Bonus]*[Bonus Payout 32]*(1-[Cap Rate 32])+([Month 32]+[Month 31])/2*[Avg Base 32]*[Avg Commission]*[Attainment 32]*(1-[Cap Rate 32]))*[PT 32],([Month 32]+[Month 31])/2*[Avg Base 32]*([Cap Rate 32]),([Month 32]+[Month 31])/2*[Avg Base 32]*[Avg Bonus]*[Bonus Payout 32]*([Cap Rate 32]),(([Month 32]+[Month 31])/2*[Avg Base 32]*([Cap Rate 32])+([Month 32]+[Month 31])/2*[Avg Base 32]*[Avg Bonus]*[Bonus Payout 32]*([Cap Rate 32]))*[PT 32],[Avg Base 32],[Avg Bonus],[Avg Commission],[Attainment 32],[PT 32],[Bonus Payout 32],[Cap Rate 32]),
(DATEADD(m,32,start_date),[Month 33],[Month 33]-[Month 32],([Month 33]+[Month 32])/2*[Avg Base 33]*(1-[Cap Rate 33]),([Month 33]+[Month 32])/2*[Avg Base 33]*[Avg Bonus]*[Bonus Payout 33]*(1-[Cap Rate 33]),([Month 33]+[Month 32])/2*[Avg Base 33]*[Avg Commission]*[Attainment 33]*(1-[Cap Rate 33]),(([Month 33]+[Month 32])/2*[Avg Base 33]*(1-[Cap Rate 33])+([Month 33]+[Month 32])/2*[Avg Base 33]*[Avg Bonus]*[Bonus Payout 33]*(1-[Cap Rate 33])+([Month 33]+[Month 32])/2*[Avg Base 33]*[Avg Commission]*[Attainment 33]*(1-[Cap Rate 33]))*[PT 33],([Month 33]+[Month 32])/2*[Avg Base 33]*([Cap Rate 33]),([Month 33]+[Month 32])/2*[Avg Base 33]*[Avg Bonus]*[Bonus Payout 33]*([Cap Rate 33]),(([Month 33]+[Month 32])/2*[Avg Base 33]*([Cap Rate 33])+([Month 33]+[Month 32])/2*[Avg Base 33]*[Avg Bonus]*[Bonus Payout 33]*([Cap Rate 33]))*[PT 33],[Avg Base 33],[Avg Bonus],[Avg Commission],[Attainment 33],[PT 33],[Bonus Payout 33],[Cap Rate 33]),
(DATEADD(m,33,start_date),[Month 34],[Month 34]-[Month 33],([Month 34]+[Month 33])/2*[Avg Base 34]*(1-[Cap Rate 34]),([Month 34]+[Month 33])/2*[Avg Base 34]*[Avg Bonus]*[Bonus Payout 34]*(1-[Cap Rate 34]),([Month 34]+[Month 33])/2*[Avg Base 34]*[Avg Commission]*[Attainment 34]*(1-[Cap Rate 34]),(([Month 34]+[Month 33])/2*[Avg Base 34]*(1-[Cap Rate 34])+([Month 34]+[Month 33])/2*[Avg Base 34]*[Avg Bonus]*[Bonus Payout 34]*(1-[Cap Rate 34])+([Month 34]+[Month 33])/2*[Avg Base 34]*[Avg Commission]*[Attainment 34]*(1-[Cap Rate 34]))*[PT 34],([Month 34]+[Month 33])/2*[Avg Base 34]*([Cap Rate 34]),([Month 34]+[Month 33])/2*[Avg Base 34]*[Avg Bonus]*[Bonus Payout 34]*([Cap Rate 34]),(([Month 34]+[Month 33])/2*[Avg Base 34]*([Cap Rate 34])+([Month 34]+[Month 33])/2*[Avg Base 34]*[Avg Bonus]*[Bonus Payout 34]*([Cap Rate 34]))*[PT 34],[Avg Base 34],[Avg Bonus],[Avg Commission],[Attainment 34],[PT 34],[Bonus Payout 34],[Cap Rate 34]),
(DATEADD(m,34,start_date),[Month 35],[Month 35]-[Month 34],([Month 35]+[Month 34])/2*[Avg Base 35]*(1-[Cap Rate 35]),([Month 35]+[Month 34])/2*[Avg Base 35]*[Avg Bonus]*[Bonus Payout 35]*(1-[Cap Rate 35]),([Month 35]+[Month 34])/2*[Avg Base 35]*[Avg Commission]*[Attainment 35]*(1-[Cap Rate 35]),(([Month 35]+[Month 34])/2*[Avg Base 35]*(1-[Cap Rate 35])+([Month 35]+[Month 34])/2*[Avg Base 35]*[Avg Bonus]*[Bonus Payout 35]*(1-[Cap Rate 35])+([Month 35]+[Month 34])/2*[Avg Base 35]*[Avg Commission]*[Attainment 35]*(1-[Cap Rate 35]))*[PT 35],([Month 35]+[Month 34])/2*[Avg Base 35]*([Cap Rate 35]),([Month 35]+[Month 34])/2*[Avg Base 35]*[Avg Bonus]*[Bonus Payout 35]*([Cap Rate 35]),(([Month 35]+[Month 34])/2*[Avg Base 35]*([Cap Rate 35])+([Month 35]+[Month 34])/2*[Avg Base 35]*[Avg Bonus]*[Bonus Payout 35]*([Cap Rate 35]))*[PT 35],[Avg Base 35],[Avg Bonus],[Avg Commission],[Attainment 35],[PT 35],[Bonus Payout 35],[Cap Rate 35]),
(DATEADD(m,35,start_date),[Month 36],[Month 36]-[Month 35],([Month 36]+[Month 35])/2*[Avg Base 36]*(1-[Cap Rate 36]),([Month 36]+[Month 35])/2*[Avg Base 36]*[Avg Bonus]*[Bonus Payout 36]*(1-[Cap Rate 36]),([Month 36]+[Month 35])/2*[Avg Base 36]*[Avg Commission]*[Attainment 36]*(1-[Cap Rate 36]),(([Month 36]+[Month 35])/2*[Avg Base 36]*(1-[Cap Rate 36])+([Month 36]+[Month 35])/2*[Avg Base 36]*[Avg Bonus]*[Bonus Payout 36]*(1-[Cap Rate 36])+([Month 36]+[Month 35])/2*[Avg Base 36]*[Avg Commission]*[Attainment 36]*(1-[Cap Rate 36]))*[PT 36],([Month 36]+[Month 35])/2*[Avg Base 36]*([Cap Rate 36]),([Month 36]+[Month 35])/2*[Avg Base 36]*[Avg Bonus]*[Bonus Payout 36]*([Cap Rate 36]),(([Month 36]+[Month 35])/2*[Avg Base 36]*([Cap Rate 36])+([Month 36]+[Month 35])/2*[Avg Base 36]*[Avg Bonus]*[Bonus Payout 36]*([Cap Rate 36]))*[PT 36],[Avg Base 36],[Avg Bonus],[Avg Commission],[Attainment 36],[PT 36],[Bonus Payout 36],[Cap Rate 36])
) cx (monthx,[Total Headcount],[Incremental Headcount],[Base Expensed],[Bonus Expensed],[Commissions Expensed],[Payroll Taxes Expensed],[Base Capitalized],[Bonus Capitalized],[Payroll Taxes Capitalized],[Avg Base],[Avg Bonus],[Avg Commissions],[Commission Attainment],[Payroll Tax Rate],[Bonus Payout],[Cap Rate])
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=u.company_number
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=u.location_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=u.bu_number
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=u.dept_number
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=u.hfm_team_code
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=u.job_id
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=u.scenario_id
LEFT JOIN BudgetDB.dbo.currency_rates cr ON cr.conversion_month=cx.monthx
AND cr.from_currency=u.currency_code AND cr.to_currency=@curr
--	fail over to Forecast scenario (ID = 2) if NULL in currency_rates table
AND ISNULL(cr.scenario_id,2)=@scenarioID
LEFT JOIN #TempSalaries sd ON sd.company_name=cp.company_name
AND sd.location_name=lc.location_name AND sd.bu_name=bu.bu_name
AND sd.dept_name=dp.dept_name AND sd.team_consolidation=tm.team_consolidation
AND sd.job_title=jt.job_title
LEFT JOIN #TempDummySalaries sdd ON sdd.job_title=jt.job_title
--	to minimize size of the set, remove any records where no revelant data exists
WHERE (cx.[Total Headcount]<>0 OR cx.[Incremental Headcount]<>0)
--	also filter based on desired date range
AND monthx BETWEEN @startMonth AND @endMonth

GO
