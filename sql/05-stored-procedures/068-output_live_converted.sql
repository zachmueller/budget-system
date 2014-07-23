USE BudgetDB
GO

IF OBJECT_ID('dbo.output_live_converted', 'P') IS NOT NULL
	DROP PROCEDURE dbo.output_live_converted
GO


CREATE PROCEDURE dbo.output_live_converted
	@curr NVARCHAR(3)
	,@wbID INT = 0			--	0 = return NULLs;	-1 = return unfiltered (for Frozen Versions); NULL = only when pivoting, hide workbook narrow SQL
	,@pivotScenario NVARCHAR(256) = NULL	--	NULL = return regular;	str = prep for pivoting (remove Actuals/Frozen Versions)
	,@revScenarioID INT = NULL
	,@returnString BIT = 0	--	0 = return data;	1 = return SQL string (helpful for debugging)
AS
/*
summary:	>
			IMPORTANT: Needs significant refactoring
			to remove the unnecessary level of
			complexity. Should break up this procedure
			into many smaller functions - essentially
			breaking each Master Assumptions calculation
			into separate functions, then UNIONing and
			filtering all in this procedure.
			This is the main calculation query of
			the database. The output of this query will
			apply the Master Assumptions to the
			current dbo.live_forecast data (creating
			additional calculated records of data)
			and return data to fill the P&L, optionally
			filtering down by a provided workbook's
			selected dimensions.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-23
*/
SET NOCOUNT ON

IF ( @wbID = 0 )
BEGIN	--	return NULL data, but keep same column structure to maintain pivot table in Excel
SELECT NULL [Scenario],NULL [Division],NULL [Company],NULL [Business Unit],NULL [Department]
	,NULL [Team], NULL [Team Consolidation],NULL [Product],NULL [Location],NULL [Job Title],NULL [P&L Item], NULL [Description]
	,NULL [Month 1],NULL [Month 2],NULL [Month 3],NULL [Month 4],NULL [Month 5],NULL [Month 6]
	,NULL [Month 7],NULL [Month 8],NULL [Month 9],NULL [Month 10],NULL [Month 11],NULL [Month 12]
	,NULL [Month 13],NULL [Month 14],NULL [Month 15],NULL [Month 16],NULL [Month 17],NULL [Month 18]
	,NULL [Month 19],NULL [Month 20],NULL [Month 21],NULL [Month 22],NULL [Month 23],NULL [Month 24]
	,NULL [Month 25],NULL [Month 26],NULL [Month 27],NULL [Month 28],NULL [Month 29],NULL [Month 30]
	,NULL [Month 31],NULL [Month 32],NULL [Month 33],NULL [Month 34],NULL [Month 35],NULL [Month 36]
	,NULL [GL Company],NULL [GL Location],NULL [GL Account],NULL [GL Team],NULL [GL BU],NULL [GL Department],NULL [GL Product]
	,NULL [Category], NULL [id],NULL [Workbook], NULL [Sheet], NULL [Row]
	,NULL [Parent1], NULL [Parent2], NULL [Parent3], NULL [Parent4]
END

ELSE

BEGIN
	--	override workbook ID if set to NULL (pivot data run)
	IF ( @wbID IS NULL ) SET @wbID = 0
	--	Declare all necessary variables
	DECLARE @loopCounter INT
		,@startDate DATE
		,@usIntlComment NVARCHAR(25)
		,@currencyComment NVARCHAR(25)
		--	variables for frozen scenario data
		,@scn1ID INT
		,@scn2ID INT
		,@scn3ID INT
		,@scn4ID INT
		,@scn5ID INT
		,@startOffsetSn1 INT
		,@startOffsetSn2 INT
		,@startOffsetSn3 INT
		,@startOffsetSn4 INT
		,@startOffsetSn5 INT
		,@scn1SQL NVARCHAR(MAX)
		,@scn2SQL NVARCHAR(MAX)
		,@scn3SQL NVARCHAR(MAX)
		,@scn4SQL NVARCHAR(MAX)
		,@scn5SQL NVARCHAR(MAX)
		--	variables for currency conversion
		,@currencyOut NVARCHAR(MAX) = ''
		,@currencyIn NVARCHAR(MAX) = ''
		,@currencyStartDate NVARCHAR(10) = ''
		,@currencyEndDate NVARCHAR(10) = ''
		,@currencySQL NVARCHAR(MAX) = ''
		--	variables for the calculated queries' SELECT statements
		,@baseSQL NVARCHAR(MAX)
		,@bonusSQL NVARCHAR(MAX)
		,@commissionSQL NVARCHAR(MAX)
		,@salaryPtSQL NVARCHAR(MAX)
		,@pbSQL NVARCHAR(MAX)
		,@phSQL NVARCHAR(MAX) = ''
		,@expPtSQL NVARCHAR(MAX) = ''
		,@sbcPtSQL NVARCHAR(MAX) = ''
		,@sbcSQL NVARCHAR(MAX) = ''
		,@forecastExpSQL NVARCHAR(MAX) = ''
		,@hcSQL NVARCHAR(MAX) = ''
		,@narrowSQL NVARCHAR(MAX) = ''
		--	variables for Actuals
		,@actualsScenarioID INT = 0
		,@actualsMonth INT = 1
		,@actualsYear INT = 0
		,@actualsYearOffset INT = 0
		,@actualsYearChar CHAR(1) = ''
		,@actualsNormalSQL NVARCHAR(MAX) = ''
		,@actualsTables NVARCHAR(MAX) = ''
		,@wbCpActuals NVARCHAR(MAX) = ''
		,@wbBuActuals NVARCHAR(MAX) = ''
		,@wbDpActuals NVARCHAR(MAX) = ''
		,@wbTmActuals NVARCHAR(MAX) = ''
		,@wbLcActuals NVARCHAR(MAX) = ''
		,@wbPdActuals NVARCHAR(MAX) = ''
		,@CpActuals NVARCHAR(MAX) = ''
		,@BuActuals NVARCHAR(MAX) = ''
		,@DpActuals NVARCHAR(MAX) = ''
		,@TmActuals NVARCHAR(MAX) = ''
		,@LcActuals NVARCHAR(MAX) = ''
		,@PdActuals NVARCHAR(MAX) = ''
		,@GlActuals NVARCHAR(MAX) = ''
		,@CrActuals NVARCHAR(MAX) = ''
		,@glCp NVARCHAR(MAX) = ''
		,@glProd NVARCHAR(MAX) = ''
		,@glLoc NVARCHAR(MAX) = ''
		,@glAcct NVARCHAR(MAX) = ''
		,@glTeam NVARCHAR(MAX) = ''
		,@glBU NVARCHAR(MAX) = ''
		,@glDept NVARCHAR(MAX) = ''
		--	Primary SQL string variable
		,@fullSQL NVARCHAR(MAX)
		,@tempTables NVARCHAR(MAX)
		,@cr NVARCHAR(10) = CHAR(13)+CHAR(10)
		,@forecastScenarioID INT = (
			SELECT TOP 1 scenario_id 
			FROM BudgetDB.dbo.scenarios 
			WHERE scenario_name='Forecast')
		,@revenueWhere NVARCHAR(256)
		--	variables necessary for pivot data output
		,@commentOpenActuals NVARCHAR(10) = ''
		,@commentOpenFV1 NVARCHAR(10) = ''
		,@commentOpenFV2to5 NVARCHAR(10) = ''
		,@commentOpenLiveForecast NVARCHAR(10) = ''
		,@commentOpenNarrow NVARCHAR(10) = ''
		,@commentCloseActuals NVARCHAR(10) = ''
		,@commentCloseFV1 NVARCHAR(10) = ''
		,@commentCloseFV2to5 NVARCHAR(10) = ''
		,@commentCloseLiveForecast NVARCHAR(10) = ''
		,@commentCloseNarrow NVARCHAR(10) = ''
		
------------------------------------------------------------------------------------------------------
--		PRE LOOP DEFINITIONS
------------------------------------------------------------------------------------------------------
	--	Set variables necessary in all run types of sproc
	SET @loopCounter = 0
	SET @startDate = (SELECT TOP 1 start_date FROM BudgetDB.dbo.scenarios WHERE scenario_name=ISNULL(@pivotScenario,'Forecast'))
	SET @currencyComment = ''
	SET @scn1SQL = ''
	SET @scn2SQL = ''
	SET @scn3SQL = ''
	SET @scn4SQL = ''
	SET @scn5SQL = ''
	SET @currencySQL = ''
	SET @narrowSQL = ''
	SET @fullSQL = ''
	
	SET @revenueWhere = ''
	IF ( @revScenarioID IS NOT NULL )
	BEGIN
		SET @revenueWhere = '
WHERE lf.scenario_id IN (' + CAST(@forecastScenarioID AS NVARCHAR)
	+ ',' + CAST(ISNULL(@revScenarioID, 0) AS NVARCHAR) + ')'
	END
	
	SET @tempTables = @cr + 'IF OBJECT_ID(''tempdb..#TempPT'') IS NOT NULL DROP TABLE #TempPT
IF OBJECT_ID(''tempdb..#TempAvgBase'') IS NOT NULL DROP TABLE #TempAvgBase
IF OBJECT_ID(''tempdb..#TempAvgBonus'') IS NOT NULL DROP TABLE #TempAvgBonus
IF OBJECT_ID(''tempdb..#TempAvgCommission'') IS NOT NULL DROP TABLE #TempAvgCommission
IF OBJECT_ID(''tempdb..#TempMonthlyRates'') IS NOT NULL DROP TABLE #TempMonthlyRates

SELECT spt.scenario_id, spt.company_number, spt.bu_number, spt.hfm_account_code
,spt.[Month 1],spt.[Month 2],spt.[Month 3],spt.[Month 4],spt.[Month 5],spt.[Month 6]
,spt.[Month 7],spt.[Month 8],spt.[Month 9],spt.[Month 10],spt.[Month 11],spt.[Month 12]
,spt.[Month 13],spt.[Month 14],spt.[Month 15],spt.[Month 16],spt.[Month 17],spt.[Month 18]
,spt.[Month 19],spt.[Month 20],spt.[Month 21],spt.[Month 22],spt.[Month 23],spt.[Month 24]
,spt.[Month 25],spt.[Month 26],spt.[Month 27],spt.[Month 28],spt.[Month 29],spt.[Month 30]
,spt.[Month 31],spt.[Month 32],spt.[Month 33],spt.[Month 34],spt.[Month 35],spt.[Month 36]
INTO #TempPT
FROM BudgetDB.dbo.calculation_table_salary_payroll_taxes spt
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=spt.scenario_id
AND sn.scenario_name=''Forecast''
WHERE spt.bu_number IS NOT NULL

INSERT INTO #TempPT (scenario_id, company_number, bu_number, hfm_account_code
,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6]
,[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12]
,[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30]
,[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT spt.scenario_id, spt.company_number, bu.bu_number, spt.hfm_account_code
,spt.[Month 1],spt.[Month 2],spt.[Month 3],spt.[Month 4],spt.[Month 5],spt.[Month 6]
,spt.[Month 7],spt.[Month 8],spt.[Month 9],spt.[Month 10],spt.[Month 11],spt.[Month 12]
,spt.[Month 13],spt.[Month 14],spt.[Month 15],spt.[Month 16],spt.[Month 17],spt.[Month 18]
,spt.[Month 19],spt.[Month 20],spt.[Month 21],spt.[Month 22],spt.[Month 23],spt.[Month 24]
,spt.[Month 25],spt.[Month 26],spt.[Month 27],spt.[Month 28],spt.[Month 29],spt.[Month 30]
,spt.[Month 31],spt.[Month 32],spt.[Month 33],spt.[Month 34],spt.[Month 35],spt.[Month 36]
FROM BudgetDB.dbo.calculation_table_salary_payroll_taxes spt
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=spt.scenario_id
AND sn.scenario_name=''Forecast''
LEFT JOIN BudgetDB.dbo.business_units bu
ON bu.bu_number=ISNULL(spt.bu_number, bu.bu_number)
WHERE bu.active_forecast_option=1
AND bu.bu_number NOT IN (
	SELECT DISTINCT bu_number
	FROM #TempPT
)'

	SET @tempTables = @tempTables + @cr + 'SELECT a.scenario_id, a.company_number,a.bu_number,a.dept_number
	,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) hfm_team_code
	,a.location_number,a.job_id,a.hfm_account_code,a.currency_code
	,CASE WHEN LEFT(jt.job_title,5)=''dummy'' THEN 1 ELSE 0 END dummy_job
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
	,SUM(a.ft_pt_count*[Month 36])/SUM(a.ft_pt_count) [Month 36]' + '
INTO #TempAvgBase
FROM BudgetDB.dbo.calculation_table_base a
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name=''Forecast'' AND sn.scenario_id=a.scenario_id
GROUP BY a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
	,a.location_number,a.job_id,a.hfm_account_code,a.currency_code
	,CASE WHEN LEFT(jt.job_title,5)=''dummy'' THEN 1 ELSE 0 END'
	SET @tempTables = @tempTables + '
SELECT a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) hfm_team_code
	,CASE WHEN LEFT(jt.job_title,5)=''dummy'' THEN 1 ELSE 0 END dummy_job
	,a.location_number,a.job_id,a.hfm_account_code,SUM(ft_pt_count*bonus_percent)/SUM(ft_pt_count) [avg_bonus]
INTO #TempAvgBonus
FROM BudgetDB.dbo.calculation_table_bonus a
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name=''Forecast'' AND sn.scenario_id=a.scenario_id
GROUP BY a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
	,a.location_number,a.job_id,a.hfm_account_code,CASE WHEN LEFT(jt.job_title,5)=''dummy'' THEN 1 ELSE 0 END

SELECT a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) hfm_team_code
	,CASE WHEN LEFT(jt.job_title,5)=''dummy'' THEN 1 ELSE 0 END dummy_job
	,a.location_number,a.job_id,a.hfm_account_code,SUM(ft_pt_count*commission_percent)/SUM(ft_pt_count) [avg_commission]
INTO #TempAvgCommission
FROM BudgetDB.dbo.calculation_table_commission a
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name=''Forecast'' AND sn.scenario_id=a.scenario_id
GROUP BY a.scenario_id,a.company_number,a.bu_number,a.dept_number,COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
	,a.location_number,a.job_id,a.hfm_account_code,CASE WHEN LEFT(jt.job_title,5)=''dummy'' THEN 1 ELSE 0 END'
	
	SET @baseSQL = ',lf.[Month 1]*COALESCE(ba.[Month 1],badm.[Month 1],0)*(1-ISNULL(cap.[Month 1],0))' 
		+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, 1, 'COALESCE(ba.currency_code,badm.currency_code,cp.currency_code)=''' + @curr + '''')
		+ ' [Month 1]'
	SET @bonusSQL = ',lf.[Month 1]*COALESCE(ba.[Month 1],badm.[Month 1],0)*COALESCE(bn.avg_bonus,bndm.avg_bonus,0)'
		+ '*bp.[Month 1]*(1-ISNULL(cap.[Month 1],0))'
		+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, 1, 'COALESCE(ba.currency_code,badm.currency_code,cp.currency_code)=''' + @curr + '''')
		+ ' [Month 1]'
	SET @commissionSQL = ',lf.[Month 1]*COALESCE(ba.[Month 1],badm.[Month 1],0)*COALESCE(cm.avg_commission,cmdm.avg_commission,0)'
		+ '*cma.[Month 1]*(1-ISNULL(cap.[Month 1],0))'
		+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, 1, 'COALESCE(ba.currency_code,badm.currency_code,cp.currency_code)=''' + @curr + '''')
		+ ' [Month 1]'
	SET @salaryPtSQL = ',(lf.[Month 1]*COALESCE(ba.[Month 1],badm.[Month 1],0)*COALESCE(cm.avg_commission,cmdm.avg_commission,0)*cma.[Month 1]'
		+ '+lf.[Month 1]*COALESCE(ba.[Month 1],badm.[Month 1],0)*COALESCE(bn.avg_bonus,bndm.avg_bonus,0)*bp.[Month 1]' 
		+ '+lf.[Month 1]*COALESCE(ba.[Month 1],badm.[Month 1],0))*pt.[Month 1]*'
		+ '(1-ISNULL(cap.[Month 1],0))'
		+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, 1, 'COALESCE(ba.currency_code,badm.currency_code,cp.currency_code)=''' + @curr + '''')
		+ ' [Month 1]'
	SET @pbSQL = ',lf.[Month 1]*COALESCE(ba.[Month 1],badm.[Month 1],0)*(1-ISNULL(cap.[Month 1],0))*pb.[Month 1]'
		+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, 1, 'COALESCE(ba.currency_code,badm.currency_code,cp.currency_code)=''' + @curr + '''')
		+ ' [Month 1]'
	
	--	prevent potential SQL injections
	SET @curr = REPLACE(ISNULL(@curr,''),'''','')
	
	--	set variable to narrow Live Forecast by JOINs
	SET @narrowSQL = @cr + dbo.fnOutputNarrowJoins(@wbID, 'lf')
	
	
	
------------------------------------------------------------------------------------------------------
--		default values when running for Frozen Versions sproc (@wbID = -1)
------------------------------------------------------------------------------------------------------
	IF ( @wbID = -1 )
	BEGIN
		SET @currencyComment = '--	'
	END
	
	
	
	
------------------------------------------------------------------------------------------------------
--		setup logic if valid worbook_id provided (i.e., for P&L refresh)
------------------------------------------------------------------------------------------------------
	IF ( @wbID >= 0 )
	BEGIN
		
		--	set currency related variables
		SET @currencyOut = ''
		SET @currencyIn = ''
		SET @currencyStartDate = CONVERT(NVARCHAR(10),@startDate,120)	--Date Format: yyyy-mm-dd
		SET @currencyEndDate = CONVERT(NVARCHAR(10),DATEADD(m,35,@startDate),120)	--Date Format: yyyy-mm-dd
		
		
		
		--	set Actuals related variables
		SET @actualsScenarioID = (SELECT TOP 1 scenario_id FROM BudgetDB.dbo.scenarios WHERE scenario_name='Actual')
		SET @usIntlComment = ''
		
		--	other variables for Actuals
		SET @actualsMonth = MONTH(@startDate)
		SET @actualsYear = YEAR(@startDate)
		SET @actualsYearOffset = 0
		SET @actualsYearChar = '1'
		SET @actualsNormalSQL = ''
		SET @wbCpActuals = 'ISNULL(wbcp.company_number,a1.company_number)=a1.company_number'
		SET @wbBuActuals = 'ISNULL(wbbu.bu_number,a1.bu_number)=a1.bu_number'
		SET @wbDpActuals = 'ISNULL(wbdp.dept_number,a1.dept_number)=a1.dept_number'
		SET @wbTmActuals = 'ISNULL(wbtm.hfm_team_code,a1.hfm_team_code)=a1.hfm_team_code'
		SET @wbLcActuals = 'ISNULL(wblc.location_number,a1.location_number)=a1.location_number'
		SET @wbPdActuals = 'ISNULL(wbpd.hfm_product_code,a1.hfm_product_code)=a1.hfm_product_code'
		SET @CpActuals = 'a1.company_number'
		SET @BuActuals = 'a1.bu_number'
		SET @DpActuals = 'a1.dept_number'
		SET @TmActuals = 'a1.hfm_team_code'
		SET @LcActuals = 'a1.location_number'
		SET @PdActuals = 'a1.hfm_product_code'
		SET @GlActuals = 'a1.hfm_account_code'
		SET @CrActuals = 'a1.currency_code'
		SET @glCp = 'a1.company_number'
		SET @glProd = 'a1.hfm_product_code'
		SET @glLoc = 'a1.location_number'
		SET @glAcct = 'a1.hfm_account_code'
		SET @glTeam = 'a1.hfm_team_code'
		SET @glBU = 'a1.bu_number'
		SET @glDept = 'a1.dept_number'
		
		--	set to comment out additional join parameter in main query
		IF (
			SELECT TOP 1 us_0_intl_1
			FROM BudgetDB.dbo.workbooks
			WHERE workbook_id=@wbID
			) IS NULL
		BEGIN
			SET @usIntlComment = '--'
		END
		--	override to include HFM journal entries for year 2013
		IF (@actualsYear)=2013
		BEGIN
			 SET @actualsTables = @cr + 'FROM (SELECT company_number, bu_number, '
				+ 'dept_number, hfm_team_code, hfm_product_code, location_number, hfm_account_code, currency_code, [Month 1], [Month 2], '
				+ '[Month 3], [Month 4], [Month 5], [Month 6], [Month 7], [Month 8], [Month 9], [Month 10], [Month 11], [Month 12] '
				+ 'FROM HFM_ActualsDB.dbo.actuals_' + CAST((@actualsYear + @actualsYearOffset) AS NVARCHAR) 
				+ ' UNION ALL SELECT company_number, bu_number, dept_number, hfm_team_code, hfm_product_code, location_number, '
				+ 'hfm_account_code, NULL currency_code, [Month 1], [Month 2], [Month 3], [Month 4], [Month 5], [Month 6], [Month 7], [Month 8], '
				+ '[Month 9], [Month 10], [Month 11], [Month 12] FROM HFM_ActualsDB.dbo.journal_entries_'
				+ CAST((@actualsYear + @actualsYearOffset) AS NVARCHAR) + ') a1'
		END
		ELSE
		BEGIN
			SET @actualsTables = @cr+'FROM HFM_ActualsDB.dbo.actuals_' + CAST(@actualsYear AS NVARCHAR) + ' a1'
		END
		
		
		--	Gather frozen scenario data
		SELECT scenario_id, ROW_NUMBER() OVER (PARTITION BY workbook_id ORDER BY scenario_id DESC) RN
		INTO #TempScenarioIDs
		FROM BudgetDB.dbo.workbook_scenarios wbsn
		WHERE wbsn.workbook_id=@wbID
		
		--	Collect top 5 scenarios selected to be included for workbook
		SET @scn1ID = (SELECT TOP 1 scenario_id FROM #TempScenarioIDs WHERE RN=1)
		SET @scn2ID = (SELECT TOP 1 scenario_id FROM #TempScenarioIDs WHERE RN=2)
		SET @scn3ID = (SELECT TOP 1 scenario_id FROM #TempScenarioIDs WHERE RN=3)
		SET @scn4ID = (SELECT TOP 1 scenario_id FROM #TempScenarioIDs WHERE RN=4)
		SET @scn5ID = (SELECT TOP 1 scenario_id FROM #TempScenarioIDs WHERE RN=5)
		--	find the date offset between frozen version and live Forecast (in months)
		SET @startOffsetSn1 = DATEDIFF(m,(SELECT TOP 1 start_date FROM BudgetDB.dbo.scenarios WHERE scenario_id=@scn1ID),@startDate)
		SET @startOffsetSn2 = DATEDIFF(m,(SELECT TOP 1 start_date FROM BudgetDB.dbo.scenarios WHERE scenario_id=@scn2ID),@startDate)
		SET @startOffsetSn3 = DATEDIFF(m,(SELECT TOP 1 start_date FROM BudgetDB.dbo.scenarios WHERE scenario_id=@scn3ID),@startDate)
		SET @startOffsetSn4 = DATEDIFF(m,(SELECT TOP 1 start_date FROM BudgetDB.dbo.scenarios WHERE scenario_id=@scn4ID),@startDate)
		SET @startOffsetSn5 = DATEDIFF(m,(SELECT TOP 1 start_date FROM BudgetDB.dbo.scenarios WHERE scenario_id=@scn5ID),@startDate)
		
	END
	
	
	--	additional steps if called by Pivot Data feature
	IF ( @pivotScenario IS NOT NULL )
	BEGIN
		IF ( @pivotScenario = 'Forecast' )
		BEGIN	--	if using live Forecast scenario, comment out only frozen versions and Actuals
			SET @commentOpenActuals = '/*'
			SET @commentOpenFV1 = '/*'
			SET @commentOpenFV2to5 = '/*'
			SET @commentOpenLiveForecast = ''
			
			SET @commentCloseActuals = '*/'
			SET @commentCloseFV1 = '*/'
			SET @commentCloseFV2to5 = '*/'
			SET @commentCloseLiveForecast = ''
		END
		ELSE
		BEGIN	--	if using Frozen Version, comment out only frozen versions 2-5, live Forecast (including temp tables), and Actuals
			SET @commentOpenActuals = '/*'
			SET @commentOpenFV1 = ''
			SET @commentOpenFV2to5 = '/*'
			SET @commentOpenLiveForecast = '/*'
			
			SET @commentCloseActuals = '*/'
			SET @commentCloseFV1 = ''
			SET @commentCloseFV2to5 = '*/'
			SET @commentCloseLiveForecast = '*/'
			
			--	reset frozen scenario variables to create required data pull
			SET @scn1ID = (SELECT TOP 1 scenario_id FROM BudgetDB.dbo.scenarios WHERE scenario_name=@pivotScenario)
			SET @scn2ID = NULL
			SET @scn3ID = NULL
			SET @scn4ID = NULL
			SET @scn5ID = NULL
			--	set the offset to 0, as the @startDate was set to that of the Frozen Version already
			SET @startOffsetSn1 = 0
			SET @startOffsetSn2 = NULL
			SET @startOffsetSn3 = NULL
			SET @startOffsetSn4 = NULL
			SET @startOffsetSn5 = NULL
		END
		
		IF ( @wbID IS NULL OR @wbID = 0 )
		BEGIN	--	if no workbook_id selected for pivot (i.e., dump all forecast data) add comments to narrow SQL
			SET @commentOpenNarrow = '/*'
			SET @commentCloseNarrow = '*/'
			SET @narrowSQL = '/*' + @narrowSQL + '*/'
		END
	END
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
	
	WHILE @loopCounter < 36
	BEGIN
		--	currency pivot table strings
		SET @currencyOut = @currencyOut + ',[' + CAST(CAST(DATEADD(m,@loopCounter,@startDate) AS DATE) AS NVARCHAR)
			+ '] AS [Month ' + CAST((@loopCounter + 1) AS NVARCHAR) + ']'
		SET @currencyIn = @currencyIn + '[' + CAST(CAST(DATEADD(m,@loopCounter,@startDate) AS DATE) AS NVARCHAR) + '],'
		
		
		SET @loopCounter = @loopCounter + 1
		
		
		--	scenario query builders
		IF @startOffsetSn1 IS NOT NULL 
		BEGIN
			Set @startOffsetSn1 = @startOffsetSn1 + 1
			IF @startOffsetSn1 BETWEEN 1 AND 36
			BEGIN
				SET @scn1SQL = @scn1SQL + ',fv.[Month ' + CAST(@startOffsetSn1 AS NVARCHAR) + ']'
					+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'pl.dollar_amount=0 OR ISNULL(fv.local_currency,cp.currency_code)=''' + @curr + '''')
					+ '[Month '	+ CAST(@loopCounter AS NVARCHAR) + ']'
			END ELSE BEGIN
				SET @scn1SQL = @scn1SQL + ',NULL [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			END
		END
		
		IF @startOffsetSn2 IS NOT NULL 
		BEGIN
			Set @startOffsetSn2 = @startOffsetSn2 + 1
			IF @startOffsetSn2 BETWEEN 1 AND 36
			BEGIN
				SET @scn2SQL = @scn2SQL + ',fv.[Month ' + CAST(@startOffsetSn2 AS NVARCHAR) + ']'
					+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'pl.dollar_amount=0 OR ISNULL(fv.local_currency,cp.currency_code)=''' + @curr + '''')
					+ '[Month '	+ CAST(@loopCounter AS NVARCHAR) + ']'
			END ELSE BEGIN
				SET @scn2SQL = @scn2SQL + ',NULL [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			END
		END
		
		IF @startOffsetSn3 IS NOT NULL 
		BEGIN
			Set @startOffsetSn3 = @startOffsetSn3 + 1
			IF @startOffsetSn3 BETWEEN 1 AND 36
			BEGIN
				SET @scn3SQL = @scn3SQL + ',fv.[Month ' + CAST(@startOffsetSn3 AS NVARCHAR) + ']'
					+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'pl.dollar_amount=0 OR ISNULL(fv.local_currency,cp.currency_code)=''' + @curr + '''')
					+ '[Month '	+ CAST(@loopCounter AS NVARCHAR) + ']'
			END ELSE BEGIN
				SET @scn3SQL = @scn3SQL + ',NULL [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			END
		END
		
		IF @startOffsetSn4 IS NOT NULL 
		BEGIN
			Set @startOffsetSn4 = @startOffsetSn4 + 1
			IF @startOffsetSn4 BETWEEN 1 AND 36
			BEGIN
				SET @scn4SQL = @scn4SQL + ',fv.[Month ' + CAST(@startOffsetSn4 AS NVARCHAR) + ']'
					+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'pl.dollar_amount=0 OR ISNULL(fv.local_currency,cp.currency_code)=''' + @curr + '''')
					+ '[Month '	+ CAST(@loopCounter AS NVARCHAR) + ']'
			END ELSE BEGIN
				SET @scn4SQL = @scn4SQL + ',NULL [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			END
		END
		
		IF @startOffsetSn5 IS NOT NULL 
		BEGIN
			Set @startOffsetSn5 = @startOffsetSn5 + 1
			IF @startOffsetSn5 BETWEEN 1 AND 36
			BEGIN
				SET @scn5SQL = @scn5SQL + ',fv.[Month ' + CAST(@startOffsetSn5 AS NVARCHAR) + ']'
					+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'pl.dollar_amount=0 OR ISNULL(fv.local_currency,cp.currency_code)=''' + @curr + '''')
					+ '[Month '	+ CAST(@loopCounter AS NVARCHAR) + ']'
			END ELSE BEGIN
				SET @scn5SQL = @scn5SQL + ',NULL [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			END
		END
		
		
		SET @phSQL = @phSQL + @cr
			+ ',lf.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']*ph.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + '''')
			+ ' [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
		SET @expPtSQL = @expPtSQL + @cr
			+ ',lf.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']*ph.[Month ' + CAST(@loopCounter AS NVARCHAR) 
			+ ']*ept.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + '''')
			+ ' [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
		SET @sbcPtSQL = @sbcPtSQL + @cr
			+ ',sbc.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']*pt.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + '''')
			+ ' [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
		SET @sbcSQL = @sbcSQL + @cr + ',sbc.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + '''')
			+ ' [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
		SET @forecastExpSQL = @forecastExpSQL + @cr + ',lf.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'ISNULL(lf.currency_code,cp.currency_code)=''' + @curr + '''')
			+ ' [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
		SET @hcSQL = @hcSQL + @cr + ',lf.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']'


		IF @loopCounter > 1
		BEGIN
			SET @pbSQL = @pbSQL + @cr
				+ ',(lf.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']+lf.[Month ' + CAST((@loopCounter - 1) AS NVARCHAR)
				+ '])/2*COALESCE(ba.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],badm.[Month ' + CAST(@loopCounter AS NVARCHAR) 
				+ '],0)*(1-ISNULL(cap.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],0))*pb.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']' 
				+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'COALESCE(ba.currency_code,badm.currency_code,cp.currency_code)=''' + @curr + '''')
				+ ' [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			SET @baseSQL = @baseSQL + @cr
				+ ',(lf.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']+lf.[Month ' + CAST((@loopCounter - 1) AS NVARCHAR)
				+ '])/2*COALESCE(ba.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],badm.[Month ' + CAST(@loopCounter AS NVARCHAR) 
				+ '],0)*(1-ISNULL(cap.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],0))'
				+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'COALESCE(ba.currency_code,badm.currency_code,cp.currency_code)=''' + @curr + '''')
				+ ' [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			SET @bonusSQL = @bonusSQL + @cr
				+ ',(lf.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']+lf.[Month ' + CAST((@loopCounter - 1) AS NVARCHAR)
				+ '])/2*COALESCE(ba.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],badm.[Month ' + CAST(@loopCounter AS NVARCHAR)
				+ '],0)*COALESCE(bn.avg_bonus,bndm.avg_bonus,0)*bp.[Month ' + CAST(@loopCounter AS NVARCHAR) 
				+ ']*(1-ISNULL(cap.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],0))'
				+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'COALESCE(ba.currency_code,badm.currency_code,cp.currency_code)=''' + @curr + '''')
				+ ' [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			SET @commissionSQL = @commissionSQL + @cr
				+ ',(lf.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']+lf.[Month ' + CAST((@loopCounter - 1) AS NVARCHAR)
				+ '])/2*COALESCE(ba.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],badm.[Month ' + CAST(@loopCounter AS NVARCHAR)
				+ '],0)*COALESCE(cm.avg_commission,cmdm.avg_commission,0)*ISNULL(cma.[Month ' + CAST(@loopCounter AS NVARCHAR) 
				+ '],0)*(1-ISNULL(cap.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],0))' 
				+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'COALESCE(ba.currency_code,badm.currency_code,cp.currency_code)=''' + @curr + '''')
				+ ' [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
			SET @salaryPtSQL = @salaryPtSQL + @cr
				+ ',((lf.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']+lf.[Month ' + CAST((@loopCounter - 1) AS NVARCHAR)
				+ '])/2*COALESCE(ba.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],badm.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],0)'
				+ '*COALESCE(bn.avg_bonus,bndm.avg_bonus,0)*bp.[Month ' + CAST(@loopCounter AS NVARCHAR) 
				+ ']+(lf.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']+lf.[Month ' + CAST((@loopCounter - 1) AS NVARCHAR)
				+ '])/2*COALESCE(ba.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],badm.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],0)'
				+ '*COALESCE(cm.avg_commission,cmdm.avg_commission,0)*ISNULL(cma.[Month ' + CAST(@loopCounter AS NVARCHAR) 
				+ '],0)+(lf.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']+lf.[Month ' + CAST((@loopCounter - 1) AS NVARCHAR)
				+ '])/2*COALESCE(ba.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],badm.[Month ' + CAST(@loopCounter AS NVARCHAR) 
				+ '],0))*pt.[Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
				+ '*(1-ISNULL(cap.[Month ' + CAST(@loopCounter AS NVARCHAR) + '],0))'
				+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'COALESCE(ba.currency_code,badm.currency_code,cp.currency_code)=''' + @curr + '''')
				+ ' [Month ' + CAST(@loopCounter AS NVARCHAR) + ']'
		END
		
		
		SET @actualsNormalSQL = @actualsNormalSQL + ',ISNULL(a' + @actualsYearChar + '.[Month ' + CAST(@actualsMonth AS NVARCHAR) + '],0)'
			+ BudgetDB.dbo.fnOutputCurrencyString(@wbID, @loopCounter, 'pl.dollar_amount=0 OR ISNULL(a' + @actualsYearChar + '.currency_code,cp.currency_code)=''' + @curr + '''')
			+ ' [Month ' + CAST(@loopCounter AS NVARCHAR) + ']' +CHAR(13)+CHAR(10)
		
		--	increment actualsMonth with each loop as it progresses through the forecast months
		SET @actualsMonth = @actualsMonth + 1
		--	once actualsMonth jumps into another year, join on additional actuals tables
		IF @actualsMonth > 12
		BEGIN
			SET @actualsMonth = 1
			SET @actualsYearOffset = @actualsYearOffset + 1
			SET @actualsYearChar = CAST((@actualsYearOffset + 1) AS NVARCHAR)
			
			IF @loopCounter < 36
			BEGIN
				IF (@actualsYear + @actualsYearOffset)=2013
				BEGIN
					SET @actualsTables = @actualsTables + @cr + 'FULL OUTER JOIN (SELECT company_number, bu_number, '
						+ 'dept_number, hfm_team_code, hfm_product_code, location_number, hfm_account_code, currency_code, [Month 1], [Month 2], '
						+ '[Month 3], [Month 4], [Month 5], [Month 6], [Month 7], [Month 8], [Month 9], [Month 10], [Month 11], [Month 12] '
						+ 'FROM HFM_ActualsDB.dbo.actuals_' + CAST((@actualsYear + @actualsYearOffset) AS NVARCHAR) 
						+ ' UNION ALL SELECT company_number, bu_number, dept_number, hfm_team_code, hfm_product_code, location_number, '
						+ 'hfm_account_code, NULL currency_code, [Month 1], [Month 2], [Month 3], [Month 4], [Month 5], [Month 6], [Month 7], [Month 8], '
						+ '[Month 9], [Month 10], [Month 11], [Month 12] FROM HFM_ActualsDB.dbo.journal_entries_'
						+ CAST((@actualsYear + @actualsYearOffset) AS NVARCHAR) + ') a' + @actualsYearChar + @cr
						+ 'ON a' + @actualsYearChar + '.company_number=a1.company_number AND a' + @actualsYearChar + '.bu_number=a1.bu_number '
						+ 'AND a' + @actualsYearChar + '.dept_number=a1.dept_number AND a' + @actualsYearChar + '.hfm_team_code=a1.hfm_team_code '
						+ 'AND a' + @actualsYearChar + '.hfm_product_code=a1.hfm_product_code AND a' + @actualsYearChar + '.location_number=a1.location_number '
						+ 'AND a' + @actualsYearChar + '.hfm_account_code=a1.hfm_account_code AND a' + @actualsYearChar + '.currency_code=a1.currency_code'
				END
				ELSE
				BEGIN
					SET @actualsTables = @actualsTables + @cr + 'FULL OUTER JOIN HFM_ActualsDB.dbo.actuals_' 
						+ CAST((@actualsYear + @actualsYearOffset) AS NVARCHAR) + ' a' + @actualsYearChar + @cr
						+ 'ON a' + @actualsYearChar + '.company_number=a1.company_number AND a' + @actualsYearChar + '.bu_number=a1.bu_number '
						+ 'AND a' + @actualsYearChar + '.dept_number=a1.dept_number AND a' + @actualsYearChar + '.hfm_team_code=a1.hfm_team_code '
						+ 'AND a' + @actualsYearChar + '.hfm_product_code=a1.hfm_product_code AND a' + @actualsYearChar + '.location_number=a1.location_number '
						+ 'AND a' + @actualsYearChar + '.hfm_account_code=a1.hfm_account_code AND a' + @actualsYearChar + '.currency_code=a1.currency_code'
				END
				
				
				SET @wbCpActuals = @wbCpActuals + ' OR ISNULL(wbcp.company_number,a' + @actualsYearChar + '.company_number)=a' 
					+ @actualsYearChar + '.company_number'
				SET @wbBuActuals = @wbBuActuals + ' OR ISNULL(wbbu.bu_number,a' + @actualsYearChar + '.bu_number)=a'
					+ @actualsYearChar + '.bu_number'
				SET @wbDpActuals = @wbDpActuals + ' OR ISNULL(wbdp.dept_number,a' + @actualsYearChar + '.dept_number)=a'
					+ @actualsYearChar + '.dept_number'
				SET @wbLcActuals = @wbLcActuals + ' OR ISNULL(wblc.location_number,a' + @actualsYearChar + '.location_number)=a'
					+ @actualsYearChar + '.location_number'
 				
				SET @CpActuals = @CpActuals + ',a' + @actualsYearChar + '.company_number'
				SET @BuActuals = @BuActuals + ',a' + @actualsYearChar + '.bu_number'
				SET @DpActuals = @DpActuals + ',a' + @actualsYearChar + '.dept_number'
				SET @TmActuals = @TmActuals + ',a' + @actualsYearChar + '.hfm_team_code'
				SET @LcActuals = @LcActuals + ',a' + @actualsYearChar + '.location_number'
				SET @PdActuals = @PdActuals + ',a' + @actualsYearChar + '.hfm_product_code'
				SET @GlActuals = @GlActuals + ',a' + @actualsYearChar + '.hfm_account_code'
				SET @CrActuals = @CrActuals + ',a' + @actualsYearChar + '.currency_code'
				
				SET @glCp = @glCp + ',a' + @actualsYearChar + '.company_number'
				SET @glProd = @glProd + ',a' + @actualsYearChar + '.hfm_product_code'
				SET @glLoc = @glLoc + ',a' + @actualsYearChar + '.location_number'
				SET @glAcct = @glAcct + ',a' + @actualsYearChar + '.hfm_account_code'
				SET @glTeam = @glTeam + ',a' + @actualsYearChar + '.hfm_team_code'
				SET @glBU = @glBU + ',a' + @actualsYearChar + '.bu_number'
				SET @glDept = @glDept + ',a' + @actualsYearChar + '.dept_number'
			END
		END
	END

	--	remove last comma in currency column list
	SET @currencyIn = LEFT(@currencyIn,LEN(@currencyIn)-1)
	
	
	--	begin building fullSQL string
	SET @fullSQL = 'SET NOCOUNT ON' + @cr + @commentOpenLiveForecast
		+ @tempTables + @commentCloseLiveForecast + @cr
	
	IF ( @wbID >= 0 )
	BEGIN
		--	finalize currency SQL string prior to concatenating fullSQL string
		SET @currencySQL = '
SELECT scenario_id, from_currency, to_currency' + @currencyOut + '
INTO #TempMonthlyRates
FROM (
	SELECT scenario_id, from_currency,to_currency,conversion_month,conversion_rate
	FROM BudgetDB.dbo.currency_rates
	WHERE to_currency=''' + @curr + ''' AND conversion_month BETWEEN '''
	+ @currencyStartDate + ''' AND ''' + @currencyEndDate + ''' AND conversion_type=''AVG_RATE''
	AND (scenario_id IS NULL OR scenario_id IN (' + CAST(@actualsScenarioID AS NVARCHAR)
		+ ',' + CASE WHEN @scn1ID IS NULL THEN 'NULL' ELSE CAST(@scn1ID AS NVARCHAR) END
		+ ',' + CASE WHEN @scn2ID IS NULL THEN 'NULL' ELSE CAST(@scn2ID AS NVARCHAR) END
		+ ',' + CASE WHEN @scn3ID IS NULL THEN 'NULL' ELSE CAST(@scn3ID AS NVARCHAR) END
		+ ',' + CASE WHEN @scn4ID IS NULL THEN 'NULL' ELSE CAST(@scn4ID AS NVARCHAR) END
		+ ',' + CASE WHEN @scn5ID IS NULL THEN 'NULL' ELSE CAST(@scn5ID AS NVARCHAR) END
		+ '))
	UNION ALL
	SELECT ' + CAST(@actualsScenarioID AS NVARCHAR) + ' scenario_id,from_currency,to_currency,conversion_month,conversion_rate
	FROM BudgetDB.dbo.currency_rates
	WHERE to_currency=''' + @curr + ''' AND conversion_month BETWEEN (
		SELECT DATEADD(m,1,MAX(conversion_month))
		FROM BudgetDB.dbo.currency_rates
		WHERE scenario_id=' + CAST(@actualsScenarioID AS NVARCHAR) + '
	) AND ''' + @currencyEndDate + ''' AND conversion_type=''AVG_RATE''
) p
PIVOT (
	MAX(conversion_rate) FOR conversion_month IN
	(' + @currencyIn + ')
) AS pvt
'
		--	pull together complete SQL query
		SET @fullSQL = @fullSQL + @currencySQL
		SET @fullSQL = @fullSQL + @cr + @commentOpenActuals + '
SELECT ''Actual'' [Scenario],dv.division_name [Division]
	,cp.company_name [Company],bu.bu_name [Business Unit],dp.dept_name [Department]
	,tm.team_name [Team],tm.team_consolidation [Team Consolidation],pd.product_name [Product]
	,CASE WHEN lc.real_location=0 THEN ''Default'' ELSE lc.location_name END [Location]
	,NULL [Job Title]
	,CASE WHEN pl.rollup_to_hosting_revenue=1 THEN 
		CASE WHEN pd.product_type_code=''PROD_CLD'' THEN ''Cloud Hosting Revenue''
		ELSE pl.pl_item END
	ELSE
		CASE WHEN pl.category_code IS NULL THEN pl.pl_item
		ELSE pl.pl_item + '' - '' + pl.category_code END
	END [P&L Item]
	,NULL [Description]
	' + @actualsNormalSQL + '
	,COALESCE(' + @glCp + ') [GL Company],COALESCE(' + @glLoc + ') [GL Location]
	,CASE WHEN ISNUMERIC(LEFT(COALESCE(' + @glAcct + '),6))=1 THEN LEFT(COALESCE(' + @glAcct + '),6)
		ELSE COALESCE(' + @glAcct + ') END [GL Account]
	,COALESCE(' + @glTeam + ') [GL Team], COALESCE(' + @glBU + ') [GL BU], COALESCE(' + @glDept + ') [GL Department]
	,LEFT(COALESCE(' + @glProd + '),4) [GL Product],NULL [Category]
	,NULL [id], 0 [Workbook], NULL [Sheet], NULL [Row]
	,cch.parent1 [Parent1],cch.parent2 [Parent2],cch.parent3 [Parent3],cch.parent4 [Parent4]
' + @actualsTables + '
LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=' + CAST(@wbID AS NVARCHAR) + '
JOIN BudgetDB.dbo.departments dp ON dp.dept_number=COALESCE(' + @DpActuals + ')
'+ @usIntlComment + '
JOIN BudgetDB.dbo.business_units bur ON bur.bu_number=COALESCE(' + @BuActuals + ')
JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=bur.hist_to_current_bu_mapping
'+ @usIntlComment + '
JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=COALESCE(' + @TmActuals + ')
'+ @usIntlComment + '
JOIN BudgetDB.dbo.locations lc ON lc.location_number=COALESCE(' + @LcActuals + ')
'+ @usIntlComment + '
JOIN BudgetDB.dbo.companies cp ON cp.company_number=COALESCE(' + @CpActuals + ')
'+ @usIntlComment + '	AND COALESCE(cp.us_0_intl_1,wb.us_0_intl_1,'''')=ISNULL(wb.us_0_intl_1,'''')
JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=COALESCE(' + @PdActuals + ')
'+ @usIntlComment + '
JOIN BudgetDB.dbo.workbook_business_units wbbu ON wbbu.workbook_id=wb.workbook_id AND ISNULL(wbbu.bu_number,bu.bu_number)=bu.bu_number
JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=wb.workbook_id AND ISNULL(wbcp.company_number,cp.company_number)=cp.company_number
JOIN BudgetDB.dbo.workbook_departments wbdp ON wbdp.workbook_id=wb.workbook_id AND ISNULL(wbdp.dept_number,dp.dept_number)=dp.dept_number
JOIN BudgetDB.dbo.workbook_locations wblc ON wblc.workbook_id=wb.workbook_id AND ISNULL(wblc.location_number,lc.location_number)=lc.location_number
JOIN BudgetDB.dbo.workbook_products wbpd ON wbpd.workbook_id=wb.workbook_id AND ISNULL(wbpd.hfm_product_code,pd.hfm_product_code)=pd.hfm_product_code
JOIN BudgetDB.dbo.workbook_teams wbtm ON wbtm.workbook_id=wb.workbook_id AND ISNULL(wbtm.hfm_team_code,tm.hfm_team_code)=tm.hfm_team_code
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=bu.bu_number AND dv.dept_number=dp.dept_number
LEFT JOIN BudgetDB.dbo.pl_rollup plr ON plr.hfm_account_code=COALESCE(' + @GlActuals + ')
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=plr.hfm_account_rollup
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name=''Actual''
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=COALESCE(' + @CrActuals + ',cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND sn.scenario_id=cr.scenario_id

UNION ALL
' + @commentCloseActuals

	END
	
	
	SET @fullSQL = @fullSQL + @commentOpenLiveForecast + dbo.fnOutputSelectPreMonths(@wbID, 'lf', 'pl.hfm_account_code')
		+ @baseSQL + dbo.fnOutputSelectPostMonths(@wbID, 'lf', 'pl.hfm_account_code') + '
FROM BudgetDB.dbo.live_forecast lf
JOIN BudgetDB.dbo.pl_items plh ON plh.hfm_account_code=lf.hfm_account_code AND plh.pl_item=''Headcount''
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=lf.hfm_team_code
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=lf.bu_number AND dv.dept_number=lf.dept_number
LEFT JOIN #TempAvgBase badm ON badm.job_id=lf.job_id AND badm.scenario_id=lf.scenario_id
	AND badm.company_number=lf.company_number AND badm.dummy_job=1
LEFT JOIN #TempAvgBase ba ON ba.scenario_id=lf.scenario_id AND ba.company_number=lf.company_number
	AND ba.bu_number=lf.bu_number AND ba.dept_number=lf.dept_number 
	AND ba.hfm_team_code=COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) AND ba.location_number=lf.location_number
	AND ba.job_id=lf.job_id AND ba.dummy_job=0
LEFT JOIN BudgetDB.dbo.calculation_table_cap_rates cap ON cap.id=lf.id
LEFT JOIN BudgetDB.dbo.pl_items pldm ON pldm.hfm_account_code=ISNULL(ba.hfm_account_code,badm.hfm_account_code)
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.pl_item=pldm.pl_item AND pl.category_code=dv.category_code
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=lf.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=lf.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=lf.scenario_id
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=lf.location_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=lf.job_id
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=lf.company_number
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=lf.hfm_product_code
LEFT JOIN BudgetDB.dbo.categories ct ON ct.category_id=lf.category_id
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @currencyComment + 'LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=COALESCE(ba.currency_code,badm.currency_code,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL' 
+ @narrowSQL + '
WHERE lf.sheet_name=''Headcount''

UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'lf', 'pl.hfm_account_code') 
	+ @bonusSQL + dbo.fnOutputSelectPostMonths(@wbID, 'lf', 'pl.hfm_account_code') + '
FROM BudgetDB.dbo.live_forecast lf
JOIN BudgetDB.dbo.pl_items plh ON plh.hfm_account_code=lf.hfm_account_code AND plh.pl_item=''Headcount''
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=lf.hfm_team_code
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=lf.bu_number AND dv.dept_number=lf.dept_number
LEFT JOIN #TempAvgBase badm ON badm.job_id=lf.job_id AND badm.scenario_id=lf.scenario_id
	AND badm.company_number=lf.company_number AND badm.dummy_job=1
LEFT JOIN #TempAvgBase ba ON ba.scenario_id=lf.scenario_id AND ba.company_number=lf.company_number
	AND ba.bu_number=lf.bu_number AND ba.dept_number=lf.dept_number 
	AND ba.hfm_team_code=COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) AND ba.location_number=lf.location_number
	AND ba.job_id=lf.job_id AND ba.dummy_job=0
LEFT JOIN BudgetDB.dbo.calculation_table_cap_rates cap ON cap.id=lf.id
LEFT JOIN #TempAvgBonus bn ON bn.scenario_id=lf.scenario_id AND bn.company_number=lf.company_number
	AND bn.bu_number=lf.bu_number AND bn.dept_number=lf.dept_number
	AND bn.hfm_team_code=COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
	AND bn.location_number=lf.location_number AND bn.job_id=lf.job_id AND bn.dummy_job=0
LEFT JOIN #TempAvgBonus bndm ON bndm.scenario_id=lf.scenario_id AND bndm.job_id=lf.job_id AND bndm.dummy_job=1
LEFT JOIN BudgetDB.dbo.calculation_table_bonus_payout_pct bp ON bp.scenario_id=lf.scenario_id
LEFT JOIN BudgetDB.dbo.pl_items pldm ON pldm.hfm_account_code=ISNULL(bn.hfm_account_code,bndm.hfm_account_code)
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.pl_item=pldm.pl_item AND pl.category_code=dv.category_code
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=lf.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=lf.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=lf.scenario_id
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=lf.location_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=lf.job_id
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=lf.company_number
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=lf.hfm_product_code
LEFT JOIN BudgetDB.dbo.categories ct ON ct.category_id=lf.category_id
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @currencyComment + 'LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=COALESCE(ba.currency_code,badm.currency_code,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL' 
+ @narrowSQL + '
WHERE lf.sheet_name=''Headcount''

UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'lf', 'pl.hfm_account_code') 
	+ @commissionSQL + dbo.fnOutputSelectPostMonths(@wbID, 'lf', 'pl.hfm_account_code') + '
FROM BudgetDB.dbo.live_forecast lf
JOIN BudgetDB.dbo.pl_items plh ON plh.hfm_account_code=lf.hfm_account_code AND plh.pl_item=''Headcount''
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=lf.hfm_team_code
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=lf.bu_number AND dv.dept_number=lf.dept_number
LEFT JOIN #TempAvgBase badm ON badm.job_id=lf.job_id AND badm.scenario_id=lf.scenario_id
	AND badm.company_number=lf.company_number AND badm.dummy_job=1
LEFT JOIN #TempAvgBase ba ON ba.scenario_id=lf.scenario_id AND ba.company_number=lf.company_number
	AND ba.bu_number=lf.bu_number AND ba.dept_number=lf.dept_number 
	AND ba.hfm_team_code=COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) AND ba.location_number=lf.location_number
	AND ba.job_id=lf.job_id AND ba.dummy_job=0
LEFT JOIN BudgetDB.dbo.calculation_table_cap_rates cap ON cap.id=lf.id
LEFT JOIN #TempAvgCommission cm ON cm.scenario_id=lf.scenario_id AND cm.company_number=lf.company_number
	AND cm.bu_number=lf.bu_number AND cm.dept_number=lf.dept_number
	AND cm.hfm_team_code=COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
	AND cm.location_number=lf.location_number AND cm.job_id=lf.job_id AND cm.dummy_job=0
LEFT JOIN #TempAvgCommission cmdm ON cmdm.scenario_id=lf.scenario_id AND cmdm.job_id=lf.job_id AND cmdm.dummy_job=1
LEFT JOIN BudgetDB.dbo.calculation_table_commission_attainment cma 
	ON cma.scenario_id=lf.scenario_id AND cma.workbook_id=lf.workbook_id
LEFT JOIN BudgetDB.dbo.pl_items pldm ON pldm.hfm_account_code=ISNULL(cm.hfm_account_code,cmdm.hfm_account_code)
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.pl_item=pldm.pl_item AND pl.category_code=dv.category_code
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=lf.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=lf.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=lf.scenario_id
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=lf.location_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=lf.job_id
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=lf.company_number
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=lf.hfm_product_code
LEFT JOIN BudgetDB.dbo.categories ct ON ct.category_id=lf.category_id
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @currencyComment + 'LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=COALESCE(ba.currency_code,badm.currency_code,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL' 
+ @narrowSQL + '
WHERE lf.sheet_name=''Headcount''

UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'lf', 'pt.hfm_account_code')
	+ @salaryPtSQL + dbo.fnOutputSelectPostMonths(@wbID, 'lf', 'pt.hfm_account_code') + '
FROM BudgetDB.dbo.live_forecast lf
JOIN BudgetDB.dbo.pl_items plh ON plh.hfm_account_code=lf.hfm_account_code AND plh.pl_item=''Headcount''
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=lf.hfm_team_code
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=lf.bu_number AND dv.dept_number=lf.dept_number
LEFT JOIN #TempAvgBase badm ON badm.job_id=lf.job_id AND badm.scenario_id=lf.scenario_id
	AND badm.company_number=lf.company_number AND badm.dummy_job=1
LEFT JOIN #TempAvgBase ba ON ba.scenario_id=lf.scenario_id AND ba.company_number=lf.company_number
	AND ba.bu_number=lf.bu_number AND ba.dept_number=lf.dept_number 
	AND ba.hfm_team_code=COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) AND ba.location_number=lf.location_number
	AND ba.job_id=lf.job_id AND ba.dummy_job=0
LEFT JOIN BudgetDB.dbo.calculation_table_cap_rates cap ON cap.id=lf.id
LEFT JOIN #TempAvgBonus bn ON bn.scenario_id=lf.scenario_id AND bn.company_number=lf.company_number
	AND bn.bu_number=lf.bu_number AND bn.dept_number=lf.dept_number
	AND bn.hfm_team_code=COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
	AND bn.location_number=lf.location_number AND bn.job_id=lf.job_id AND bn.dummy_job=0
LEFT JOIN #TempAvgBonus bndm ON bndm.scenario_id=lf.scenario_id AND bndm.job_id=lf.job_id AND bndm.dummy_job=1
LEFT JOIN BudgetDB.dbo.calculation_table_bonus_payout_pct bp ON bp.scenario_id=lf.scenario_id
LEFT JOIN #TempAvgCommission cm ON cm.scenario_id=lf.scenario_id AND cm.company_number=lf.company_number
	AND cm.bu_number=lf.bu_number AND cm.dept_number=lf.dept_number
	AND cm.hfm_team_code=COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code)
	AND cm.location_number=lf.location_number AND cm.job_id=lf.job_id AND cm.dummy_job=0
LEFT JOIN #TempAvgCommission cmdm ON cmdm.scenario_id=lf.scenario_id AND cmdm.job_id=lf.job_id AND cmdm.dummy_job=1
LEFT JOIN BudgetDB.dbo.calculation_table_commission_attainment cma 
	ON cma.scenario_id=lf.scenario_id AND cma.workbook_id=lf.workbook_id
LEFT JOIN #TempPT pt ON pt.scenario_id=lf.scenario_id
	AND pt.company_number=lf.company_number AND pt.bu_number=lf.bu_number
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=pt.hfm_account_code
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=lf.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=lf.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=lf.scenario_id
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=lf.location_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=lf.job_id
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=lf.company_number
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=lf.hfm_product_code
LEFT JOIN BudgetDB.dbo.categories ct ON ct.category_id=lf.category_id
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @currencyComment + 'LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=COALESCE(ba.currency_code,badm.currency_code,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL' 
+ @narrowSQL + '
WHERE lf.sheet_name=''Headcount''
AND pl.category_code=dv.category_code

UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'lf', 'pl.hfm_account_code')
	+ @phSQL + dbo.fnOutputSelectPostMonths(@wbID, 'lf', 'pl.hfm_account_code') + '
FROM BudgetDB.dbo.live_forecast lf
JOIN BudgetDB.dbo.pl_items plm ON plm.hfm_account_code=lf.hfm_account_code AND plm.pl_item=''Headcount''
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=lf.bu_number AND dv.dept_number=lf.dept_number
LEFT JOIN BudgetDB.dbo.calculation_table_per_headcount_assumptions ph ON ph.scenario_id=lf.scenario_id
	AND ph.company_number=lf.company_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=ph.hfm_account_code AND pl.category_code=dv.category_code
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=lf.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=lf.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=lf.scenario_id
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=lf.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=lf.location_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=lf.job_id
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=lf.company_number
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=lf.hfm_product_code
LEFT JOIN BudgetDB.dbo.categories ct ON ct.category_id=lf.category_id
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @currencyComment + 'LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(ph.currency_code,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL'
+ @narrowSQL + '
WHERE lf.sheet_name=''Headcount''

UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'lf', 'pb.hfm_account_code')
	+ @pbSQL + dbo.fnOutputSelectPostMonths(@wbID, 'lf', 'pb.hfm_account_code') + '
FROM BudgetDB.dbo.live_forecast lf
JOIN BudgetDB.dbo.pl_items plm ON plm.hfm_account_code=lf.hfm_account_code AND plm.pl_item=''Headcount''
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=lf.hfm_team_code
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=lf.bu_number AND dv.dept_number=lf.dept_number
LEFT JOIN #TempAvgBase badm ON badm.job_id=lf.job_id AND badm.scenario_id=lf.scenario_id
	AND badm.company_number=lf.company_number AND badm.dummy_job=1
LEFT JOIN #TempAvgBase ba ON ba.scenario_id=lf.scenario_id AND ba.company_number=lf.company_number
	AND ba.bu_number=lf.bu_number AND ba.dept_number=lf.dept_number 
	AND ba.hfm_team_code=COALESCE(tm.team_consolidation,tm.team_name,tm.hfm_team_code) AND ba.location_number=lf.location_number
	AND ba.job_id=lf.job_id AND ba.dummy_job=0
LEFT JOIN BudgetDB.dbo.calculation_table_cap_rates cap ON cap.id=lf.id
LEFT JOIN BudgetDB.dbo.calculation_table_percent_of_base pb ON pb.scenario_id=lf.scenario_id
	AND pb.company_number=lf.company_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=pb.hfm_account_code AND pl.category_code=dv.category_code
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=lf.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=lf.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=lf.scenario_id
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=lf.location_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=lf.job_id
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=lf.company_number
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=lf.hfm_product_code
LEFT JOIN BudgetDB.dbo.categories ct ON ct.category_id=lf.category_id
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @currencyComment + 'LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=COALESCE(ba.currency_code,badm.currency_code,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL'
+ @narrowSQL + '
WHERE lf.sheet_name=''Headcount''

UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'lf', 'pl.hfm_account_code')
	+ @expPtSQL + dbo.fnOutputSelectPostMonths(@wbID, 'lf', 'pl.hfm_account_code') + '
FROM BudgetDB.dbo.live_forecast lf
JOIN BudgetDB.dbo.pl_items plm ON plm.hfm_account_code=lf.hfm_account_code AND plm.pl_item=''Headcount''
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=lf.bu_number AND dv.dept_number=lf.dept_number
LEFT JOIN BudgetDB.dbo.calculation_table_per_headcount_assumptions ph ON ph.scenario_id=lf.scenario_id
	AND ph.company_number=lf.company_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=ph.hfm_account_code AND pl.category_code=dv.category_code
JOIN BudgetDB.dbo.calculation_table_expense_payroll_taxes ept ON ept.scenario_id=lf.scenario_id
	AND ept.company_number=lf.company_number AND ept.hfm_expense_code=ph.hfm_account_code
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=lf.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=lf.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=lf.scenario_id
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=lf.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=lf.location_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=lf.job_id
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=lf.company_number
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=lf.hfm_product_code
LEFT JOIN BudgetDB.dbo.categories ct ON ct.category_id=lf.category_id
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @currencyComment + 'LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(ph.currency_code,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL'
+ @narrowSQL + '
WHERE lf.sheet_name=''Headcount''

UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'sbc', 'pt.hfm_account_code')
	+ @sbcPtSQL + dbo.fnOutputSelectPostMonths(@wbID, 'sbc', 'pt.hfm_account_code') + '
FROM BudgetDB.dbo.calculation_table_sbc sbc
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name=''Forecast'' AND sn.scenario_id=sbc.scenario_id
LEFT JOIN #TempPT pt ON pt.bu_number=sbc.bu_number
	AND pt.scenario_id=sbc.scenario_id AND pt.company_number=sbc.company_number
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=sbc.bu_number AND dv.dept_number=sbc.dept_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=pt.hfm_account_code
	AND pl.category_code=dv.category_code
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=sbc.company_number
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=sbc.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=sbc.bu_number
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=''0000_0000''
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=sbc.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=sbc.location_number
' + @currencyComment + 'LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(sbc.currency_code,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @commentOpenNarrow + dbo.fnOutputNarrowJoins(@wbID, 'sbc') 
 + @commentCloseNarrow + '

UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'sbc', 'sbc.hfm_account_code')
	+ @sbcSQL + dbo.fnOutputSelectPostMonths(@wbID, 'sbc', 'sbc.hfm_account_code') + '
FROM BudgetDB.dbo.calculation_table_sbc sbc
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name=''Forecast'' AND sn.scenario_id=sbc.scenario_id
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=sbc.bu_number AND dv.dept_number=sbc.dept_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=sbc.hfm_account_code AND pl.category_code=dv.category_code
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=sbc.company_number
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=sbc.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=sbc.bu_number
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=''0000_0000''
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=sbc.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=sbc.location_number
' + @currencyComment + 'LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(sbc.currency_code,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @cr + @commentOpenNarrow + dbo.fnOutputNarrowJoins(@wbID, 'sbc') 
 + @commentCloseNarrow + '

UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'lf', 'lf.hfm_account_code')
	+ @forecastExpSQL + dbo.fnOutputSelectPostMonths(@wbID, 'lf', 'lf.hfm_account_code') + '
FROM BudgetDB.dbo.live_forecast lf
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=lf.bu_number AND dv.dept_number=lf.dept_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=lf.hfm_account_code
	AND CASE WHEN pl.category_code IS NULL THEN 1
	WHEN pl.category_code=dv.category_code THEN 1
	ELSE 0 END = 1
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=lf.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=lf.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=lf.scenario_id
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=lf.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=lf.location_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=lf.job_id
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=lf.company_number
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=lf.hfm_product_code
LEFT JOIN BudgetDB.dbo.categories ct ON ct.category_id=lf.category_id
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @currencyComment + 'LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(lf.currency_code,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL'
+ @narrowSQL + @revenueWhere
+ @commentCloseLiveForecast


	--	Add in scenarios, if chosen for workbook
	IF ( @wbID >= 0 )
	BEGIN
	IF @startOffsetSn1 IS NOT NULL
	BEGIN
		SET @fullSQL = @fullSQL + @commentOpenFV1 + '
' + @commentOpenLiveForecast + 'UNION ALL' + @commentCloseLiveForecast + '

' + dbo.fnOutputSelectPreMonths(@wbID, 'fv', '') + @scn1SQL + dbo.fnOutputSelectPostMonths(@wbID, 'fv', 'fv.hfm_account_code') + '
FROM BudgetDB.dbo.frozen_versions fv
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=fv.bu_number AND dv.dept_number=fv.dept_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=fv.hfm_account_code
	AND CASE WHEN pl.category_code IS NULL THEN 1
	WHEN pl.category_code=dv.category_code THEN 1
	ELSE 0 END = 1
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=fv.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=fv.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=fv.scenario_id
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=fv.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=fv.location_number
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=fv.company_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=fv.job_id
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=fv.hfm_product_code
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @cr + @commentOpenNarrow + dbo.fnOutputNarrowJoins(@wbID, 'fv') 
 + @commentCloseNarrow + '
LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(fv.local_currency,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id=fv.scenario_id
WHERE fv.scenario_id=' + CAST(ISNULL(@scn1ID,'') AS NVARCHAR) + @commentCloseFV1
	END

	IF @startOffsetSn2 IS NOT NULL
	BEGIN
		SET @fullSQL = @fullSQL + @commentOpenFV2to5 + '
UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'fv', '') + @scn2SQL + dbo.fnOutputSelectPostMonths(@wbID, 'fv', 'fv.hfm_account_code') + '
FROM BudgetDB.dbo.frozen_versions fv
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=fv.bu_number AND dv.dept_number=fv.dept_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=fv.hfm_account_code
	AND CASE WHEN pl.category_code IS NULL THEN 1
	WHEN pl.category_code=dv.category_code THEN 1
	ELSE 0 END = 1
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=fv.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=fv.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=fv.scenario_id
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=fv.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=fv.location_number
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=fv.company_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=fv.job_id
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=fv.hfm_product_code
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @cr + dbo.fnOutputNarrowJoins(@wbID, 'fv') + '
LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(fv.local_currency,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id=fv.scenario_id
WHERE fv.scenario_id=' + CAST(ISNULL(@scn2ID,'') AS NVARCHAR) + @commentCloseFV2to5
	END

	IF @startOffsetSn3 IS NOT NULL
	BEGIN
		SET @fullSQL = @fullSQL + @commentOpenFV2to5 + '
UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'fv', '') + @scn3SQL + dbo.fnOutputSelectPostMonths(@wbID, 'fv', 'fv.hfm_account_code') + '
FROM BudgetDB.dbo.frozen_versions fv
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=fv.bu_number AND dv.dept_number=fv.dept_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=fv.hfm_account_code
	AND CASE WHEN pl.category_code IS NULL THEN 1
	WHEN pl.category_code=dv.category_code THEN 1
	ELSE 0 END = 1
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=fv.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=fv.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=fv.scenario_id
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=fv.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=fv.location_number
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=fv.company_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=fv.job_id
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=fv.hfm_product_code
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @cr + dbo.fnOutputNarrowJoins(@wbID, 'fv') + '
LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(fv.local_currency,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id=fv.scenario_id
WHERE fv.scenario_id=' + CAST(ISNULL(@scn3ID,'') AS NVARCHAR) + @commentCloseFV2to5
	END

	IF @startOffsetSn4 IS NOT NULL
	BEGIN
		SET @fullSQL = @fullSQL + @commentOpenFV2to5 + '
UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'fv', '') + @scn4SQL + dbo.fnOutputSelectPostMonths(@wbID, 'fv', 'fv.hfm_account_code') + '
FROM BudgetDB.dbo.frozen_versions fv
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=fv.bu_number AND dv.dept_number=fv.dept_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=fv.hfm_account_code
	AND CASE WHEN pl.category_code IS NULL THEN 1
	WHEN pl.category_code=dv.category_code THEN 1
	ELSE 0 END = 1
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=fv.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=fv.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=fv.scenario_id
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=fv.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=fv.location_number
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=fv.company_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=fv.job_id
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=fv.hfm_product_code
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @cr + dbo.fnOutputNarrowJoins(@wbID, 'fv') + '
LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(fv.local_currency,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id=fv.scenario_id
WHERE fv.scenario_id=' + CAST(ISNULL(@scn4ID,'') AS NVARCHAR) + @commentCloseFV2to5
	END

	IF @startOffsetSn5 IS NOT NULL
	BEGIN
		SET @fullSQL = @fullSQL + @commentCloseFV2to5 + '
UNION ALL

' + dbo.fnOutputSelectPreMonths(@wbID, 'fv', '') + @scn5SQL + dbo.fnOutputSelectPostMonths(@wbID, 'fv', 'fv.hfm_account_code') + '
FROM BudgetDB.dbo.frozen_versions fv
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=fv.bu_number AND dv.dept_number=fv.dept_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=fv.hfm_account_code
	AND CASE WHEN pl.category_code IS NULL THEN 1
	WHEN pl.category_code=dv.category_code THEN 1
	ELSE 0 END = 1
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=fv.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=fv.bu_number
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=fv.scenario_id
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=fv.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=fv.location_number
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=fv.company_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=fv.job_id
LEFT JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=fv.hfm_product_code
LEFT JOIN BudgetDB.dbo.cost_center_hierarchies cch ON cch.bu_number=bu.bu_number
AND cch.dept_number=dp.dept_number AND cch.hfm_team_code=tm.hfm_team_code
' + @cr + dbo.fnOutputNarrowJoins(@wbID, 'fv') + '
LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(fv.local_currency,cp.currency_code) AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id=fv.scenario_id
WHERE fv.scenario_id=' + CAST(ISNULL(@scn5ID,'') AS NVARCHAR) + @commentCloseFV2to5
	END
	END
	
	--	Use below to help with debugging
	IF ( @returnString = 1 )
	BEGIN
		SELECT 1, SUBSTRING(@fullSQL,1,30000)
		UNION
		SELECT 2, SUBSTRING(@fullSQL,30001,30000)
		UNION
		SELECT 3, SUBSTRING(@fullSQL,60001,30000)
		UNION
		SELECT 4, SUBSTRING(@fullSQL,90001,30000)
		UNION
		SELECT 5, SUBSTRING(@fullSQL,120001,30000)
		UNION
		SELECT 6, SUBSTRING(@fullSQL,150001,30000)
		UNION
		SELECT 7, SUBSTRING(@fullSQL,180001,30000)
		UNION
		SELECT 8, SUBSTRING(@fullSQL,210001,30000)
		
		RETURN
	END
	
	EXEC sp_executesql @fullSQL
END

GO
