USE BudgetDB
GO

IF OBJECT_ID('dbo.create_rax_cons_scenario', 'P') IS NOT NULL
	DROP PROCEDURE dbo.create_rax_cons_scenario
GO


CREATE PROCEDURE dbo.create_rax_cons_scenario
	@scenarioName NVARCHAR(256)		--	new scenario name
	,@usSnID INT		--	scenario ID for US scenario
	,@intlSnID INT		--	scenario ID for INTL scenario
AS
/*
summary:	>
			Used by FP&A analysts to create a
			global frozen scenario by combining
			one US and one INTL frozen scenario.
			WARNING: Still need to update to
			include additional historical table
			snapshots.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

--	validate name
IF EXISTS (SELECT TOP 1 scenario_id
	FROM BudgetDB.dbo.scenarios
	WHERE scenario_name = @scenarioName)
BEGIN
	--	frozen scenario name already in use
	SELECT 'The provided name has already been used, please try again and provide an unused scenario name.' o
	RETURN
END

--	validate selected scenario IDs
IF (SELECT COUNT(*) FROM BudgetDB.dbo.scenarios
	WHERE scenario_id IN (@usSnID,@intlSnID)) < 2
BEGIN
	--	scenario IDs not found
	SELECT 'One or both of the selected scenarios could not be found in the database, please re-open the workbook and try again.' o
	RETURN
END

--	check that the start dates of each scenario match
IF (
	SELECT TOP 1 DATEDIFF(d,snINTL.start_date,snUS.start_date)
	FROM BudgetDB.dbo.scenarios snUS
	LEFT JOIN BudgetDB.dbo.scenarios snINTL
	ON snINTL.scenario_id=@intlSnID
	WHERE snUS.scenario_id=@usSnID
) <> 0
BEGIN
	SELECT 'You''ve selected scenarios with different Start Dates. The ability to create a RAX Cons scenario under these circumstances has not '
		+ 'yet been built into the database. Please bug Zach to go fix this (or find somebody else who can write the needed dynamic SQL query).' o
	RETURN
END




BEGIN TRY
BEGIN TRANSACTION
--	set necessary variables
DECLARE @dateSaved DATETIME2 = GETDATE()
	,@scenarioID INT
	,@startDate DATE = (SELECT TOP 1 start_date
		FROM BudgetDB.dbo.scenarios
		WHERE scenario_id=@usSnID)

--	create table to capture scenario id
CREATE TABLE #TempScenarioID ( scenario_id INT )

--	Insert new scenario name into scenarios table and return ID
SELECT @scenarioName scenario_name
INTO #TempScenario

MERGE BudgetDB.dbo.scenarios sn
USING #TempScenario ts
ON 1=0
WHEN NOT MATCHED THEN
	INSERT (scenario_name, start_date, date_frozen, rev_scenario, us_0_intl_1)
	VALUES (@scenarioName,@startDate,@dateSaved,0,NULL)
OUTPUT inserted.scenario_id INTO #TempScenarioID;

--	move newly inserted ID into variable, drop temp table
SET @scenarioID = (SELECT TOP 1 scenario_id FROM #TempScenarioID)
DROP TABLE #TempScenarioID
DROP TABLE #TempScenario

--	copy currency rates
INSERT INTO BudgetDB.dbo.currency_rates (scenario_id, from_currency, to_currency
	,conversion_type, conversion_month, conversion_rate)
SELECT @scenarioID, from_currency, to_currency, conversion_type
	,conversion_month, conversion_rate
FROM BudgetDB.dbo.currency_rates cr
WHERE cr.scenario_id IS NULL
	AND cr.conversion_month BETWEEN @startDate AND DATEADD(m,35,@startDate)


--	create historical copies of calculation tables
INSERT INTO BudgetDB.dbo.calculation_table_base (scenario_id,company_number,bu_number,dept_number
	,hfm_team_code,location_number,job_id,ft_pt_count,hfm_account_code,currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @scenarioID,cl.company_number,cl.bu_number,cl.dept_number,cl.hfm_team_code
	,cl.location_number,cl.job_id,cl.ft_pt_count,cl.hfm_account_code,cl.currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM BudgetDB.dbo.calculation_table_base cl
WHERE cl.scenario_id IN (@usSnID,@intlSnID)

INSERT INTO BudgetDB.dbo.calculation_table_bonus (scenario_id,company_number,bu_number,dept_number
	,hfm_team_code,location_number,job_id,ft_pt_count,hfm_account_code,bonus_percent)
SELECT @scenarioID,cl.company_number,cl.bu_number,cl.dept_number,cl.hfm_team_code
	,cl.location_number,cl.job_id,cl.ft_pt_count,cl.hfm_account_code,cl.bonus_percent
FROM BudgetDB.dbo.calculation_table_bonus cl
WHERE cl.scenario_id IN (@usSnID,@intlSnID)

INSERT INTO BudgetDB.dbo.calculation_table_commission (scenario_id,company_number,bu_number,dept_number
	,hfm_team_code,location_number,job_id,ft_pt_count,hfm_account_code,commission_percent)
SELECT @scenarioID,cl.company_number,cl.bu_number,cl.dept_number,cl.hfm_team_code
	,cl.location_number,cl.job_id,cl.ft_pt_count,cl.hfm_account_code,cl.commission_percent
FROM BudgetDB.dbo.calculation_table_commission cl
WHERE cl.scenario_id IN (@usSnID,@intlSnID)

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
WHERE cl.scenario_id IN (@usSnID)

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
WHERE cl.scenario_id IN (@usSnID,@intlSnID)

INSERT INTO BudgetDB.dbo.calculation_table_per_headcount_assumptions (scenario_id,company_number
	,hfm_account_code,currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @scenarioID, cl.company_number, cl.hfm_account_code, cl.currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM BudgetDB.dbo.calculation_table_per_headcount_assumptions cl
WHERE cl.scenario_id IN (@usSnID,@intlSnID)

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
WHERE cl.scenario_id IN (@usSnID,@intlSnID)

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
WHERE cl.scenario_id IN (@usSnID,@intlSnID)

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
WHERE cl.scenario_id IN (@usSnID,@intlSnID)

INSERT INTO BudgetDB.dbo.calculation_table_sbc (scenario_id,company_number,bu_number
	,dept_number,hfm_team_code,location_number,hfm_account_code,currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @scenarioID, cl.company_number, cl.bu_number, cl.dept_number, cl.hfm_team_code
	,cl.location_number, cl.hfm_account_code, cl.currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM BudgetDB.dbo.calculation_table_sbc cl
WHERE cl.scenario_id IN (@usSnID,@intlSnID)

--	historical copies of team_consolidations, salary_data, and job_consolidations
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

INSERT INTO BudgetDB.dbo.historical_table_salary_data (scenario_id, employee_id, last_name, first_name, job_code
	,job_id, manager, ft_pt, base, bonus, commission_target, currency_code
	,company_number, location_number, bu_number, dept_number, hfm_team_code)
SELECT @scenarioID, employee_id, last_name, first_name, job_code
	,job_id, manager, ft_pt, base, bonus, commission_target, currency_code
	,company_number, location_number, bu_number, dept_number, hfm_team_code
FROM BudgetDB.dbo.historical_table_salary_data
WHERE scenario_id IN (@usSnID,@intlSnID)


--	create a temp table to hold the old and new IDs for
--		correctly inserting the historical Cap Rates
CREATE TABLE #TempCapRateIDs (
	old_id BIGINT
	,new_id BIGINT
)

--	copy headcount records from US/INTL scenarios into frozen_versions,
--		capturing the old and new IDs
MERGE BudgetDB.dbo.frozen_versions fv
USING (SELECT fv.id, @scenarioID scenario_id,fv.company_number,fv.bu_number,fv.dept_number
		,fv.hfm_team_code,fv.hfm_product_code,fv.location_number,fv.job_id
		,fv.hfm_account_code,fv.[description]
		,fv.[Month 1],fv.[Month 2],fv.[Month 3],fv.[Month 4],fv.[Month 5],fv.[Month 6]
		,fv.[Month 7],fv.[Month 8],fv.[Month 9],fv.[Month 10],fv.[Month 11],fv.[Month 12]
		,fv.[Month 13],fv.[Month 14],fv.[Month 15],fv.[Month 16],fv.[Month 17],fv.[Month 18]
		,fv.[Month 19],fv.[Month 20],fv.[Month 21],fv.[Month 22],fv.[Month 23],fv.[Month 24]
		,fv.[Month 25],fv.[Month 26],fv.[Month 27],fv.[Month 28],fv.[Month 29],fv.[Month 30]
		,fv.[Month 31],fv.[Month 32],fv.[Month 33],fv.[Month 34],fv.[Month 35],fv.[Month 36]
		,fv.forecast_method,fv.forecast_rate,fv.local_currency,fv.category_name
		,fv.workbook_id,fv.workbook_name,fv.sheet_name,fv.excel_row
		,fv.created_by,fv.created_date,fv.last_updated_by,fv.last_updated_date
	FROM BudgetDB.dbo.frozen_versions fv
	LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=fv.hfm_account_code
	WHERE pl.pl_item='Headcount' AND fv.scenario_id IN (@usSnID,@intlSnID)) s
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
FROM BudgetDB.dbo.historical_table_cap_rates cap
JOIN #TempCapRateIDs ci ON ci.old_id=cap.id

--	drop temp table
DROP TABLE #TempCapRateIDs


--	combine and copy the remaining frozen_versions data into the RAX Cons scenario
INSERT INTO BudgetDB.dbo.frozen_versions (scenario_id, company_number, bu_number, dept_number
	,hfm_team_code, hfm_product_code, location_number, job_id, hfm_account_code, [description]
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9]
	,[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27]
	,[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
	,forecast_method, forecast_rate,local_currency, category_name, workbook_id, workbook_name
	,sheet_name, excel_row, created_by, created_date, last_updated_by, last_updated_date)
SELECT @scenarioID,fv.company_number,fv.bu_number,fv.dept_number
	,fv.hfm_team_code,fv.hfm_product_code,fv.location_number,fv.job_id
	,fv.hfm_account_code,fv.[description]
	,fv.[Month 1],fv.[Month 2],fv.[Month 3],fv.[Month 4],fv.[Month 5],fv.[Month 6]
	,fv.[Month 7],fv.[Month 8],fv.[Month 9],fv.[Month 10],fv.[Month 11],fv.[Month 12]
	,fv.[Month 13],fv.[Month 14],fv.[Month 15],fv.[Month 16],fv.[Month 17],fv.[Month 18]
	,fv.[Month 19],fv.[Month 20],fv.[Month 21],fv.[Month 22],fv.[Month 23],fv.[Month 24]
	,fv.[Month 25],fv.[Month 26],fv.[Month 27],fv.[Month 28],fv.[Month 29],fv.[Month 30]
	,fv.[Month 31],fv.[Month 32],fv.[Month 33],fv.[Month 34],fv.[Month 35],fv.[Month 36]
	,fv.forecast_method,fv.forecast_rate,fv.local_currency,fv.category_name
	,fv.workbook_id,fv.workbook_name,fv.sheet_name,fv.excel_row
	,fv.created_by,fv.created_date,fv.last_updated_by,fv.last_updated_date
FROM BudgetDB.dbo.frozen_versions fv
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=fv.hfm_account_code
WHERE pl.pl_item<>'Headcount' AND fv.scenario_id IN (@usSnID,@intlSnID)


SELECT 'Successfully created the following frozen scenario:' + CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10) + @scenarioName o, 0 n

COMMIT TRANSACTION
END TRY

BEGIN CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
IF OBJECT_ID('tempdb..#TempScenarioID') IS NOT NULL DROP TABLE #TempScenarioID
IF OBJECT_ID('tempdb..#TempScenario') IS NOT NULL DROP TABLE #TempScenario
SELECT 'An error occurred in the database while trying to save the scenario:' + CHAR(13)+CHAR(10) 
	+ ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
