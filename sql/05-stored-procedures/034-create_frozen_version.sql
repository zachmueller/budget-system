USE BudgetDB
GO

IF OBJECT_ID('dbo.create_frozen_version', 'P') IS NOT NULL
	DROP PROCEDURE dbo.create_frozen_version
GO


CREATE PROCEDURE dbo.create_frozen_version
	@scenarioName NVARCHAR(256)
	,@revName NVARCHAR(256)
	,@usIntl BIT
AS

SET NOCOUNT ON

--	check provided scenario name
IF EXISTS (SELECT TOP 1 scenario_id
	FROM BudgetDB.dbo.scenarios
	WHERE scenario_name = @scenarioName)
BEGIN
	--	frozen scenario name already in use
	SELECT 'The provided name has already been used, please try again and provide an unused scenario name.' o
	RETURN
END

--	check for valid revenue scenario
IF NOT EXISTS (SELECT TOP 1 scenario_id
	FROM BudgetDB.dbo.scenarios
	WHERE scenario_name = @revName
	AND rev_scenario = 1)
BEGIN
	--	Invalid revenue scenario
	SELECT 'Invalid revenue scenario selected.' o
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:create_frozen_version' AS VARBINARY(128))
SET CONTEXT_INFO @ci


BEGIN TRY
BEGIN TRANSACTION
--	collect relevant information
DECLARE @forecastStartDate DATE = (SELECT TOP 1 start_date
	FROM BudgetDB.dbo.scenarios WHERE scenario_name='Forecast')
	,@scenarioID INT
	,@dateFrozen DATETIME2 = GETDATE()
	,@revScenarioID INT = (
		SELECT TOP 1 scenario_id
		FROM BudgetDB.dbo.scenarios
		WHERE scenario_name=@revName
		AND rev_scenario=1)

--	create table to capture scenario id
CREATE TABLE #TempScenarioID (
	scenario_id INT
)

--	Insert new scenario name into scenarios table and return ID
SELECT @scenarioName scenario_name
INTO #TempScenario

MERGE BudgetDB.dbo.scenarios sn
USING #TempScenario ts
ON 1=0
WHEN NOT MATCHED THEN
	INSERT (scenario_name, start_date, date_frozen, rev_scenario, us_0_intl_1)
	VALUES (@scenarioName,@forecastStartDate,@dateFrozen,0,@usIntl)
-- 	capture new ID in temp table
OUTPUT inserted.scenario_id INTO #TempScenarioID;


--	move newly inserted ID into variable, drop temp tables
SET @scenarioID = (SELECT TOP 1 scenario_id FROM #TempScenarioID)
DROP TABLE #TempScenarioID
DROP TABLE #TempScenario

--	copy currency rates
INSERT INTO BudgetDB.dbo.currency_rates (scenario_id
	,from_currency, to_currency, conversion_type
	,conversion_month, conversion_rate)
SELECT @scenarioID, from_currency, to_currency
	,conversion_type, conversion_month, conversion_rate
FROM BudgetDB.dbo.currency_rates cr
WHERE cr.scenario_id IS NULL
	AND cr.conversion_month BETWEEN @forecastStartDate
	AND DATEADD(m,35,@forecastStartDate)


--	create historical copies of calculation tables
--	base salaries
INSERT INTO BudgetDB.dbo.calculation_table_base (scenario_id,company_number,bu_number,dept_number
	,hfm_team_code,location_number,job_id,ft_pt_count,hfm_account_code,currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @scenarioID,cl.company_number,cl.bu_number,cl.dept_number
	,cl.hfm_team_code,cl.location_number,cl.job_id,cl.ft_pt_count,cl.hfm_account_code,cl.currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM BudgetDB.dbo.calculation_table_base cl
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=cl.scenario_id
JOIN BudgetDB.dbo.companies cp ON cp.company_number=cl.company_number AND ISNULL(cp.us_0_intl_1,@usIntl)=@usIntl
JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=cl.bu_number
JOIN BudgetDB.dbo.departments dp ON dp.dept_number=cl.dept_number
JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=cl.hfm_team_code
JOIN BudgetDB.dbo.locations lc ON lc.location_number=cl.location_number

--	average bonus
INSERT INTO BudgetDB.dbo.calculation_table_bonus (scenario_id,company_number,bu_number,dept_number
	,hfm_team_code,location_number,job_id,ft_pt_count,hfm_account_code,bonus_percent)
SELECT @scenarioID,cl.company_number,cl.bu_number,cl.dept_number,cl.hfm_team_code
	,cl.location_number,cl.job_id,cl.ft_pt_count,cl.hfm_account_code,cl.bonus_percent
FROM BudgetDB.dbo.calculation_table_bonus cl
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=cl.scenario_id
JOIN BudgetDB.dbo.companies cp ON cp.company_number=cl.company_number AND ISNULL(cp.us_0_intl_1,@usIntl)=@usIntl
JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=cl.bu_number
JOIN BudgetDB.dbo.departments dp ON dp.dept_number=cl.dept_number
JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=cl.hfm_team_code
JOIN BudgetDB.dbo.locations lc ON lc.location_number=cl.location_number

--	average commission rates
INSERT INTO BudgetDB.dbo.calculation_table_commission (scenario_id,company_number,bu_number,dept_number
	,hfm_team_code,location_number,job_id,ft_pt_count,hfm_account_code,commission_percent)
SELECT @scenarioID,cl.company_number,cl.bu_number,cl.dept_number,cl.hfm_team_code
	,cl.location_number,cl.job_id,cl.ft_pt_count,cl.hfm_account_code,cl.commission_percent
FROM BudgetDB.dbo.calculation_table_commission cl
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=cl.scenario_id
JOIN BudgetDB.dbo.companies cp ON cp.company_number=cl.company_number AND ISNULL(cp.us_0_intl_1,@usIntl)=@usIntl
JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=cl.bu_number
JOIN BudgetDB.dbo.departments dp ON dp.dept_number=cl.dept_number
JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=cl.hfm_team_code
JOIN BudgetDB.dbo.locations lc ON lc.location_number=cl.location_number

--	bonus payout percent
INSERT INTO BudgetDB.dbo.calculation_table_bonus_payout_pct (scenario_id
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @scenarioID,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM BudgetDB.dbo.calculation_table_bonus_payout_pct cl
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=cl.scenario_id

--	commission attainment
INSERT INTO BudgetDB.dbo.calculation_table_commission_attainment (scenario_id,workbook_id
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @scenarioID, cl.workbook_id,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM BudgetDB.dbo.calculation_table_commission_attainment cl
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=cl.scenario_id
JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=cl.workbook_id AND ISNULL(wb.us_0_intl_1,@usIntl)=@usIntl

--	expense assumptions dollars per headcount
INSERT INTO BudgetDB.dbo.calculation_table_per_headcount_assumptions (scenario_id,company_number,hfm_account_code
	,currency_code,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @scenarioID, cl.company_number, cl.hfm_account_code, cl.currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM BudgetDB.dbo.calculation_table_per_headcount_assumptions cl
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=cl.scenario_id
JOIN BudgetDB.dbo.companies cp ON cp.company_number=cl.company_number AND ISNULL(cp.us_0_intl_1,@usIntl)=@usIntl

--	percent of base salaries assumptions
INSERT INTO BudgetDB.dbo.calculation_table_percent_of_base (scenario_id,company_number,hfm_match_code,hfm_account_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @scenarioID, cl.company_number, cl.hfm_match_code, cl.hfm_account_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM BudgetDB.dbo.calculation_table_percent_of_base cl
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=cl.scenario_id
JOIN BudgetDB.dbo.companies cp ON cp.company_number=cl.company_number AND ISNULL(cp.us_0_intl_1,@usIntl)=@usIntl

--	salary payroll tax rates
INSERT INTO BudgetDB.dbo.calculation_table_salary_payroll_taxes (scenario_id,company_number,bu_number,hfm_account_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @scenarioID, cl.company_number, cl.bu_number, cl.hfm_account_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM BudgetDB.dbo.calculation_table_salary_payroll_taxes cl
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=cl.scenario_id
JOIN BudgetDB.dbo.companies cp ON cp.company_number=cl.company_number AND ISNULL(cp.us_0_intl_1,@usIntl)=@usIntl

--	expense payroll tax rates
INSERT INTO BudgetDB.dbo.calculation_table_expense_payroll_taxes (scenario_id,company_number,hfm_expense_code,hfm_account_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @scenarioID, cl.company_number, cl.hfm_expense_code, cl.hfm_account_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM BudgetDB.dbo.calculation_table_expense_payroll_taxes cl
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=cl.scenario_id
JOIN BudgetDB.dbo.companies cp ON cp.company_number=cl.company_number AND ISNULL(cp.us_0_intl_1,@usIntl)=@usIntl

--	stock based comp
INSERT INTO BudgetDB.dbo.calculation_table_sbc (scenario_id,company_number,bu_number,dept_number
	,hfm_team_code,location_number,hfm_account_code,currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @scenarioID, cl.company_number, cl.bu_number, cl.dept_number, cl.hfm_team_code, cl.location_number, cl.hfm_account_code
	,cl.currency_code,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM BudgetDB.dbo.calculation_table_sbc cl
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=cl.scenario_id
JOIN BudgetDB.dbo.companies cp ON cp.company_number=cl.company_number AND ISNULL(cp.us_0_intl_1,@usIntl)=@usIntl
JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=cl.bu_number
JOIN BudgetDB.dbo.departments dp ON dp.dept_number=cl.dept_number
JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=cl.hfm_team_code
JOIN BudgetDB.dbo.locations lc ON lc.location_number=cl.location_number

--	historical copies of team_consolidations, salary_data, and job_consolidations, hierarchies
INSERT INTO BudgetDB.dbo.historical_table_team_consolidation (scenario_id, hfm_team_code, team_consolidation)
SELECT @scenarioID, hfm_team_code, team_consolidation
FROM BudgetDB.dbo.teams

INSERT INTO BudgetDB.dbo.historical_table_job_title_consolidation (scenario_id, job_id, job_consolidation)
SELECT @scenarioID, jt.job_id, jt.job_consolidation
FROM BudgetDB.dbo.job_titles jt
JOIN (
	SELECT DISTINCT job_id FROM BudgetDB.dbo.live_forecast
	WHERE job_id IS NOT NULL
) lf ON lf.job_id=jt.job_id

INSERT INTO BudgetDB.dbo.historical_table_salary_data (scenario_id, employee_id
	,last_name, first_name, job_code, job_id, manager, ft_pt, base, bonus
	,commission_target, currency_code, company_number, location_number
	,bu_number, dept_number, hfm_team_code)
SELECT @scenarioID, employee_id, last_name, first_name, job_code
	,job_id, manager, ft_pt, base, bonus, commission_target, sd.currency_code
	,sd.company_number, location_number, bu_number, dept_number, hfm_team_code
FROM BudgetDB.dbo.salary_data sd

INSERT INTO BudgetDB.dbo.historical_table_cost_center_hierarchies (scenario_id, bu_number
	,dept_number, hfm_team_code, parent1, parent2, parent3, parent4)
SELECT @scenarioID, bu_number, dept_number, hfm_team_code
	,parent1, parent2, parent3, parent4
FROM BudgetDB.dbo.cost_center_hierarchies

INSERT INTO BudgetDB.dbo.historical_table_divisions (scenario_id
	,bu_number, dept_number, division_name, category_code, metric)
SELECT @scenarioID, bu_number, dept_number, division_name
	,category_code, metric
FROM BudgetDB.dbo.divisions

--	create a temp table to hold the old and new IDs for
--		correctly inserting the historical Cap Rates
CREATE TABLE #TempCapRateIDs (
	old_id INT
	,new_id BIGINT
)

--	copy headcount records from live_forecast into frozen_versions,
--		capturing the old and new IDs
MERGE BudgetDB.dbo.frozen_versions fv
USING (SELECT lf.id, @scenarioID scenario_id,lf.company_number,lf.bu_number,lf.dept_number
		,lf.hfm_team_code,lf.hfm_product_code,lf.location_number,lf.job_id
		,lf.hfm_account_code,lf.[description]
		,lf.[Month 1],lf.[Month 2],lf.[Month 3],lf.[Month 4],lf.[Month 5],lf.[Month 6]
		,lf.[Month 7],lf.[Month 8],lf.[Month 9],lf.[Month 10],lf.[Month 11],lf.[Month 12]
		,lf.[Month 13],lf.[Month 14],lf.[Month 15],lf.[Month 16],lf.[Month 17],lf.[Month 18]
		,lf.[Month 19],lf.[Month 20],lf.[Month 21],lf.[Month 22],lf.[Month 23],lf.[Month 24]
		,lf.[Month 25],lf.[Month 26],lf.[Month 27],lf.[Month 28],lf.[Month 29],lf.[Month 30]
		,lf.[Month 31],lf.[Month 32],lf.[Month 33],lf.[Month 34],lf.[Month 35],lf.[Month 36]
		,lf.forecast_method,lf.forecast_rate,ISNULL(lf.currency_code,cp.currency_code) local_currency,ct.category_name
		,lf.workbook_id,wb.workbook_name,lf.sheet_name,lf.excel_row
		,lf.created_by,lf.created_date,lf.last_updated_by,lf.last_updated_date
	FROM BudgetDB.dbo.live_forecast lf
	JOIN BudgetDB.dbo.companies cp ON cp.company_number=lf.company_number AND ISNULL(cp.us_0_intl_1,@usIntl)=@usIntl
	JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=lf.bu_number
	JOIN BudgetDB.dbo.departments dp ON dp.dept_number=lf.dept_number
	JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=lf.hfm_team_code
	JOIN BudgetDB.dbo.locations lc ON lc.location_number=lf.location_number
	JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=lf.hfm_product_code
	LEFT JOIN BudgetDB.dbo.categories ct ON ct.category_id=lf.category_id
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=lf.workbook_id
	LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=lf.hfm_account_code
	WHERE lf.sheet_name='Headcount') s
ON 1=0
WHEN NOT MATCHED THEN
	INSERT (scenario_id, company_number, bu_number, dept_number
		,hfm_team_code, hfm_product_code, location_number, job_id, hfm_account_code, [description]
		,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
		,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
		,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
		,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
		,forecast_method, forecast_rate,local_currency, category_name, workbook_id, workbook_name
		,sheet_name, excel_row, created_by, created_date, last_updated_by, last_updated_date)
	VALUES (s.scenario_id, s.company_number, s.bu_number, s.dept_number
		,s.hfm_team_code, s.hfm_product_code, s.location_number, s.job_id, s.hfm_account_code, s.[description]
		,s.[Month 1],[Month 2],s.[Month 3],[Month 4],s.[Month 5],s.[Month 6],[Month 7],s.[Month 8],s.[Month 9]
		,s.[Month 10],s.[Month 11],s.[Month 12],s.[Month 13],s.[Month 14],s.[Month 15],s.[Month 16],s.[Month 17],s.[Month 18]
		,s.[Month 19],s.[Month 20],s.[Month 21],s.[Month 22],s.[Month 23],s.[Month 24],s.[Month 25],s.[Month 26],s.[Month 27]
		,s.[Month 28],s.[Month 29],s.[Month 30],s.[Month 31],s.[Month 32],s.[Month 33],s.[Month 34],s.[Month 35],s.[Month 36]
		,s.forecast_method, s.forecast_rate,s.local_currency, s.category_name, s.workbook_id, s.workbook_name
		,s.sheet_name, s.excel_row, s.created_by, s.created_date, s.last_updated_by, s.last_updated_date)
OUTPUT s.id, inserted.id INTO #TempCapRateIDs;

--	insert cap rates into historical calculation table using old-to-new ID mapping
INSERT INTO BudgetDB.dbo.historical_table_cap_rates (id,[Month 1],[Month 2]
	,[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9],[Month 10],[Month 11]
	,[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18],[Month 19]
	,[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
	,created_by,created_date,last_updated_by,last_updated_date)
SELECT ci.new_id,cap.[Month 1],cap.[Month 2],cap.[Month 3],cap.[Month 4],cap.[Month 5],cap.[Month 6]
	,cap.[Month 7],cap.[Month 8],cap.[Month 9],cap.[Month 10],cap.[Month 11],cap.[Month 12],cap.[Month 13]
	,cap.[Month 14],cap.[Month 15],cap.[Month 16],cap.[Month 17],cap.[Month 18],cap.[Month 19]
	,cap.[Month 20],cap.[Month 21],cap.[Month 22],cap.[Month 23],cap.[Month 24],cap.[Month 25]
	,cap.[Month 26],cap.[Month 27],cap.[Month 28],cap.[Month 29],cap.[Month 30],cap.[Month 31]
	,cap.[Month 32],cap.[Month 33],cap.[Month 34],cap.[Month 35],cap.[Month 36]
	,cap.created_by,cap.created_date,cap.last_updated_by,cap.last_updated_date
FROM BudgetDB.dbo.calculation_table_cap_rates cap
JOIN #TempCapRateIDs ci ON ci.old_id=cap.id

--	drop cap rate temp table
DROP TABLE #TempCapRateIDs


--	Dump current live_forecast data into temp table
IF OBJECT_ID('tempdb..#TempForecast') IS NOT NULL DROP TABLE #TempForecast
CREATE TABLE #TempForecast(
	company_number NCHAR(3)
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
	,forecast_method NVARCHAR(256)
	,forecast_rate DECIMAL(30,16)
	,currency_code NCHAR(3)
	,category_name NVARCHAR(256)
	,workbook_id INT
	,workbook_name NVARCHAR(256)
	,sheet_name NVARCHAR(50)
	,excel_row INT
	,created_by NVARCHAR(256)
	,created_date DATETIME2
	,last_updated_by NVARCHAR(256)
	,last_updated_date DATETIME2
)

--	fill temp table by running primary output sproc
--		set to run for frozen versions
INSERT INTO #TempForecast (company_number,bu_number,dept_number
	,hfm_team_code,hfm_product_code,location_number,job_id
	,hfm_account_code,[description],[Month 1],[Month 2],[Month 3]
	,[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15]
	,[Month 16],[Month 17],[Month 18],[Month 19],[Month 20],[Month 21]
	,[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33]
	,[Month 34],[Month 35],[Month 36],forecast_method,forecast_rate
	,currency_code,category_name,workbook_id,workbook_name,sheet_name
	,excel_row,created_by,created_date,last_updated_by,last_updated_date)
EXEC dbo.output_live_converted NULL, -1, NULL, @revScenarioID

--	Dump current live_forecast data into frozen_versions tables
--		(first as numbers only, then text version)
INSERT INTO BudgetDB.dbo.frozen_versions (scenario_id, company_number, bu_number, dept_number
	,hfm_team_code, hfm_product_code, location_number, job_id, hfm_account_code, [description]
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
	,forecast_method, forecast_rate,local_currency, category_name, workbook_id, workbook_name
	,sheet_name, excel_row, created_by, created_date, last_updated_by, last_updated_date)
SELECT @scenarioID, tf.company_number,bu_number,dept_number
	,hfm_team_code,hfm_product_code,location_number,job_id
	,tf.hfm_account_code,[description],[Month 1],[Month 2],[Month 3]
	,[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15]
	,[Month 16],[Month 17],[Month 18],[Month 19],[Month 20],[Month 21]
	,[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33]
	,[Month 34],[Month 35],[Month 36],forecast_method,forecast_rate
	,tf.currency_code,category_name,workbook_id,workbook_name,sheet_name
	,excel_row,created_by,created_date,last_updated_by,last_updated_date
FROM #TempForecast tf
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=tf.company_number
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=tf.hfm_account_code
--	exclude raw headcount records, as those were inserted above
WHERE NOT (tf.sheet_name='Headcount' AND pl.pl_item='Headcount')
--	only run for selected US/INTL companies
AND ISNULL(cp.us_0_intl_1,@usIntl)=@usIntl


--	insert text version
INSERT INTO BudgetDB.dbo.frozen_versions_text (scenario_name, company_name, bu_name, dept_name
	,team_name, product_name, location_name, job_title, pl_item, [description], division_name
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
	,local_currency, category_name, workbook_name, sheet_name, excel_row, created_by, created_date
	,last_updated_by, last_updated_date, date_frozen)
SELECT sn.scenario_name, cp.company_name, bu.bu_name, dp.dept_name, tm.team_name, pd.product_name
	,lc.location_name, jt.job_title
	,CASE WHEN pl.category_code IS NULL THEN pl.pl_item
	ELSE pl.pl_item + ' - ' + pl.category_code END
	,fv.[description],dv.division_name
	,fv.[Month 1],fv.[Month 2],fv.[Month 3],fv.[Month 4],fv.[Month 5],fv.[Month 6],fv.[Month 7],fv.[Month 8],fv.[Month 9]
	,fv.[Month 10],fv.[Month 11],fv.[Month 12],fv.[Month 13],fv.[Month 14],fv.[Month 15],fv.[Month 16],fv.[Month 17],fv.[Month 18]
	,fv.[Month 19],fv.[Month 20],fv.[Month 21],fv.[Month 22],fv.[Month 23],fv.[Month 24],fv.[Month 25],fv.[Month 26],fv.[Month 27]
	,fv.[Month 28],fv.[Month 29],fv.[Month 30],fv.[Month 31],fv.[Month 32],fv.[Month 33],fv.[Month 34],fv.[Month 35],fv.[Month 36]
	,fv.local_currency, fv.category_name, fv.workbook_name, fv.sheet_name, fv.excel_row, fv.created_by, fv.created_date
	,fv.last_updated_by, fv.last_updated_date, @dateFrozen
FROM BudgetDB.dbo.frozen_versions fv
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=fv.company_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=fv.bu_number
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=fv.dept_number
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=fv.bu_number AND dv.dept_number=fv.dept_number
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=fv.hfm_team_code
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=fv.hfm_product_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=fv.location_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=fv.job_id
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=fv.hfm_account_code
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=fv.scenario_id
AND sn.scenario_id=@scenarioID

COMMIT TRANSACTION

SELECT 'Successfully created the following frozen scenario:' + CHAR(13)+CHAR(10) 
	+ CHAR(13)+CHAR(10) + @scenarioName + CHAR(13)+CHAR(10) + 'Number of records: ' 
	+ CAST(COUNT(*) AS NVARCHAR) o, COUNT(*) n, @scenarioID snID
FROM BudgetDB.dbo.frozen_versions
WHERE scenario_id=@scenarioID

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

END TRY

BEGIN CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

IF OBJECT_ID('tempdb..#TempScenarioID') IS NOT NULL DROP TABLE #TempScenarioID
IF OBJECT_ID('tempdb..#TempScenario') IS NOT NULL DROP TABLE #TempScenario
SELECT 'An error occurred in the database while trying to save the scenario:' + CHAR(13)+CHAR(10) 
	+ ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
