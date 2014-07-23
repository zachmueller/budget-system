USE BudgetDB
GO

IF OBJECT_ID('dbo.assumptions_local_actuals', 'P') IS NOT NULL
	DROP PROCEDURE dbo.assumptions_local_actuals
GO


CREATE PROCEDURE dbo.assumptions_local_actuals
	@wbID INT
	,@curr NCHAR(3) = 'USD'
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
	SELECT NULL [Division],NULL [Company],NULL [Business Unit],NULL [Department]
	,NULL [Team],NULL [Product],NULL [Location],NULL [Expense Item],NULL [Expense Item2]
	,NULL [Revenue Item],NULL [Revenue Item2],NULL [Local Currency]
	,NULL [Month 1],NULL [Month 2],NULL [Month 3]
	,NULL [Month 4],NULL [Month 5],NULL [Month 6]
	,NULL [Month 7],NULL [Month 8],NULL [Month 9]
	,NULL [Month 10],NULL [Month 11],NULL [Month 12]
	,NULL [Month 13],NULL [Month 14],NULL [Month 15]
	,NULL [Month 16],NULL [Month 17],NULL [Month 18]
	,NULL [Month 19],NULL [Month 20],NULL [Month 21]
	,NULL [Month 22],NULL [Month 23],NULL [Month 24]
	,NULL [Month 25],NULL [Month 26],NULL [Month 27]
	,NULL [Month 28],NULL [Month 29],NULL [Month 30]
	,NULL [Month 31],NULL [Month 32],NULL [Month 33]
	,NULL [Month 34],NULL [Month 35],NULL [Month 36]
END

ELSE

BEGIN	--	build dynamic SQL query to provide currency-converted output

--	collect variables
DECLARE @loopCounter INT = 0
	--	find current start date for the live Forecast
	,@startDate DATE = (SELECT TOP 1 start_date FROM BudgetDB.dbo.scenarios WHERE scenario_name='Forecast')

DECLARE @actualsMonth INT = MONTH(@startDate)
	,@actualsYear INT = YEAR(@startDate)
	,@actualsYearOffset INT = 0				--	used to point to each Actuals month's table
	,@actualsYearChar NCHAR(1) = '1'		--	appended to each table's alias
	,@actualsNormalSQL NVARCHAR(MAX) = ''	--	to hold SELECT for monthly fields

DECLARE @actualsTables NVARCHAR(MAX)		--	dynamic SQL for FROM and JOINs of actuals tables
	,@CpActuals NVARCHAR(MAX) = 'a1.company_number'
	,@BuActuals NVARCHAR(MAX) = 'a1.bu_number'
	,@DpActuals NVARCHAR(MAX) = 'a1.dept_number'
	,@TmActuals NVARCHAR(MAX) = 'a1.hfm_team_code'
	,@LcActuals NVARCHAR(MAX) = 'a1.location_number'
	,@PdActuals NVARCHAR(MAX) = 'a1.hfm_product_code'
	,@GlActuals NVARCHAR(MAX) = 'a1.hfm_account_code'
	,@CrActuals NVARCHAR(MAX) = 'a1.currency_code'
	,@currencyOut NVARCHAR(MAX) = ''
	,@currencyIn NVARCHAR(MAX) = ''
	,@currencyStartDate NVARCHAR(10) = CONVERT(NVARCHAR(10),@startDate,120)	--Date Format: yyyy-mm-dd
	,@currencyEndDate NVARCHAR(10) = CONVERT(NVARCHAR(10),DATEADD(m,35,@startDate),120)	--Date Format: yyyy-mm-dd
	,@currencySQL NVARCHAR(MAX)
	,@fullSQL NVARCHAR(MAX)


IF (@actualsYear)=2013
BEGIN	--	handle fix to incorporate HFM journal entries for 2013
	 SET @actualsTables = CHAR(13)+CHAR(10) + 'FROM (SELECT company_number, bu_number, '
		+ 'dept_number, hfm_team_code, hfm_product_code, location_number, hfm_account_code, currency_code, [Month 1], [Month 2], '
		+ '[Month 3], [Month 4], [Month 5], [Month 6], [Month 7], [Month 8], [Month 9], [Month 10], [Month 11], [Month 12] '
		+ 'FROM HFM_ActualsDB.dbo.actuals_' + CAST((@actualsYear + @actualsYearOffset) AS NVARCHAR) 
		+ ' UNION ALL SELECT company_number, bu_number, dept_number, hfm_team_code, hfm_product_code, location_number, '
		+ 'hfm_account_code, NULL currency_code, [Month 1], [Month 2], [Month 3], [Month 4], [Month 5], [Month 6], [Month 7], [Month 8], '
		+ '[Month 9], [Month 10], [Month 11], [Month 12] FROM HFM_ActualsDB.dbo.journal_entries_'
		+ CAST((@actualsYear + @actualsYearOffset) AS NVARCHAR) + ') a1'
END
ELSE
BEGIN	--	select directly from year's respective Actuals table
	SET @actualsTables = CHAR(13)+CHAR(10)+'FROM HFM_ActualsDB.dbo.actuals_' + CAST(@actualsYear AS NVARCHAR) + ' a1'
END

--	loop through full month range and build dynamic parts of the query
WHILE @loopCounter < 36
BEGIN
	--	currency pivot table strings
	--	Example: ,[2013-01-01] AS [Month 1]
	SET @currencyOut = @currencyOut + ',[' + CAST(CAST(DATEADD(m,@loopCounter,@startDate) AS DATE) AS NVARCHAR)
		+ '] AS [Month ' + CAST((@loopCounter + 1) AS NVARCHAR) + ']'
	--	Example: [2013-01-01],
	SET @currencyIn = @currencyIn + '[' + CAST(CAST(DATEADD(m,@loopCounter,@startDate) AS DATE) AS NVARCHAR) + '],'

	SET @loopCounter = @loopCounter + 1
	
	--	select out raw monthly data
	--	Example: ,ISNULL(a1.[Month 1],0) [Month 1]
	SET @actualsNormalSQL = @actualsNormalSQL + ',ISNULL(a' + @actualsYearChar + '.[Month ' + CAST(@actualsMonth AS NVARCHAR)
		+ '],0) [Month ' + CAST(@loopCounter AS NVARCHAR) + ']' +CHAR(13)+CHAR(10)
	
	SET @actualsMonth = @actualsMonth + 1
	IF @actualsMonth > 12
	BEGIN	--	if actuals months roll into next year, update variables accordingly
		--	reset month value to January
		SET @actualsMonth = 1
		--	increment the year
		SET @actualsYearOffset = @actualsYearOffset + 1
		SET @actualsYearChar = CAST((@actualsYearOffset + 1) AS NVARCHAR)
		
		
		IF @loopCounter < 36
		BEGIN	--	if more than one month remaining, JOIN additional table
			--	if 2013, implement fix for incorporating HFM journal entries
			IF (@actualsYear + @actualsYearOffset)=2013
			BEGIN
				SET @actualsTables = @actualsTables + CHAR(13)+CHAR(10) + 'FULL OUTER JOIN (SELECT company_number, bu_number, '
					+ 'dept_number, hfm_team_code, hfm_product_code, location_number, hfm_account_code, currency_code, [Month 1], [Month 2], '
					+ '[Month 3], [Month 4], [Month 5], [Month 6], [Month 7], [Month 8], [Month 9], [Month 10], [Month 11], [Month 12] '
					+ 'FROM HFM_ActualsDB.dbo.actuals_' + CAST((@actualsYear + @actualsYearOffset) AS NVARCHAR) 
					+ ' UNION ALL SELECT company_number, bu_number, dept_number, hfm_team_code, hfm_product_code, location_number, '
					+ 'hfm_account_code, [Month 1], [Month 2], [Month 3], [Month 4], [Month 5], [Month 6], [Month 7], [Month 8], '
					+ '[Month 9], [Month 10], [Month 11], [Month 12] FROM HFM_ActualsDB.dbo.journal_entries_'
					+ CAST((@actualsYear + @actualsYearOffset) AS NVARCHAR) + ') a' + @actualsYearChar + CHAR(13)+CHAR(10)
					+ 'ON a' + @actualsYearChar + '.company_number=a1.company_number AND a' + @actualsYearChar + '.bu_number=a1.bu_number '
					+ 'AND a' + @actualsYearChar + '.dept_number=a1.dept_number AND a' + @actualsYearChar + '.hfm_team_code=a1.hfm_team_code '
					+ 'AND a' + @actualsYearChar + '.hfm_product_code=a1.hfm_product_code AND a' + @actualsYearChar + '.location_number=a1.location_number '
					+ 'AND a' + @actualsYearChar + '.hfm_account_code=a1.hfm_account_code AND a' + @actualsYearChar + '.currency_code=a1.currency_code '
			END
			ELSE
			BEGIN
				SET @actualsTables = @actualsTables + CHAR(13)+CHAR(10) + 'FULL OUTER JOIN HFM_ActualsDB.dbo.actuals_' 
					+ CAST((@actualsYear + @actualsYearOffset) AS NVARCHAR) + ' a' + @actualsYearChar + CHAR(13)+CHAR(10)
					+ 'ON a' + @actualsYearChar + '.company_number=a1.company_number AND a' + @actualsYearChar + '.bu_number=a1.bu_number '
					+ 'AND a' + @actualsYearChar + '.dept_number=a1.dept_number AND a' + @actualsYearChar + '.hfm_team_code=a1.hfm_team_code '
					+ 'AND a' + @actualsYearChar + '.hfm_product_code=a1.hfm_product_code AND a' + @actualsYearChar + '.location_number=a1.location_number '
					+ 'AND a' + @actualsYearChar + '.hfm_account_code=a1.hfm_account_code AND a' + @actualsYearChar + '.currency_code=a1.currency_code '
			END
			
			--	add on additional set of fields for COALESCE in LEFT JOINs
			--	Example full output, to be wrapped in COALESCE(): a1.bu_number,a2.bu_number,a3.bu_number
			SET @CpActuals = @CpActuals + ',a' + @actualsYearChar + '.company_number'
			SET @BuActuals = @BuActuals + ',a' + @actualsYearChar + '.bu_number'
			SET @DpActuals = @DpActuals + ',a' + @actualsYearChar + '.dept_number'
			SET @TmActuals = @TmActuals + ',a' + @actualsYearChar + '.hfm_team_code'
			SET @LcActuals = @LcActuals + ',a' + @actualsYearChar + '.location_number'
			SET @PdActuals = @PdActuals + ',a' + @actualsYearChar + '.hfm_product_code'
			SET @GlActuals = @GlActuals + ',a' + @actualsYearChar + '.hfm_account_code'
			SET @CrActuals = @CrActuals + ',a' + @actualsYearChar + '.currency_code'
		END
	END
END

--	trim off last comma
SET @currencyIn = LEFT(@currencyIn,LEN(@currencyIn)-1)

SET @currencySQL = 'SELECT scenario_id, from_currency, to_currency' + @currencyOut + '
INTO #TempMonthlyRates
FROM (
	SELECT scenario_id, from_currency,to_currency,conversion_month,conversion_rate
	FROM BudgetDB.dbo.currency_rates
	WHERE to_currency=''' + @curr + ''' AND conversion_month BETWEEN '''
	+ @currencyStartDate + ''' AND ''' + @currencyEndDate + '''
	AND conversion_type=''AVG_RATE'' AND scenario_id IS NULL
) p
PIVOT (
	MAX(conversion_rate) FOR conversion_month IN
	(' + @currencyIn + ')
) AS pvt
'


SET @fullSQL = @currencySQL + 'SELECT dv.division_name [Division],cp.company_name [Company],bu.bu_name [Business Unit],dp.dept_name [Department]
	,ISNULL(tm.team_consolidation,tm.team_name) [Team],ISNULL(pd.product_consolidation,pd.product_name) [Product]
	,CASE WHEN lc.real_location=0 THEN ''Default'' ELSE lc.location_name END [Location]
	,CASE WHEN pl.rollup_to_hosting_revenue IS NOT NULL THEN NULL ELSE pl.pl_item END [Expense Item]
	,CASE WHEN pl.rollup_to_hosting_revenue IS NOT NULL THEN NULL 
		ELSE CASE WHEN pl.category_code IS NULL THEN pl.pl_item
		ELSE pl.pl_item + '' - '' + pl.category_code
	END END [Expense Item2]
	,CASE WHEN pl.rollup_to_hosting_revenue IS NULL THEN NULL
		ELSE pl.pl_item	END [Revenue Item]
	,CASE WHEN pl.rollup_to_hosting_revenue IS NOT NULL THEN
		CASE WHEN pd.product_type_code=''PROD_CLD'' AND pl.rollup_to_hosting_revenue=1
		THEN ''Cloud Hosting Revenue'' ELSE pl.pl_item END
	ELSE NULL END [Revenue Item2]
	,''' + @curr + ''' [Local Currency]
	' + @actualsNormalSQL + '
' + @actualsTables + '
LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=' + CAST(@wbID AS NVARCHAR) + '
JOIN BudgetDB.dbo.departments dp ON dp.dept_number=COALESCE(' + @DpActuals + ')
	AND ISNULL(dp.us_0_intl_1,wb.us_0_intl_1)=wb.us_0_intl_1
JOIN BudgetDB.dbo.business_units bur ON bur.bu_number=COALESCE(' + @BuActuals + ')
JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=bur.hist_to_current_bu_mapping
	AND ISNULL(bu.us_0_intl_1,wb.us_0_intl_1)=wb.us_0_intl_1
JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=COALESCE(' + @TmActuals + ')
	AND ISNULL(tm.us_0_intl_1,wb.us_0_intl_1)=wb.us_0_intl_1
JOIN BudgetDB.dbo.locations lc ON lc.location_number=COALESCE(' + @LcActuals + ')
	AND ISNULL(lc.us_0_intl_1,wb.us_0_intl_1)=wb.us_0_intl_1
JOIN BudgetDB.dbo.companies cp ON cp.company_number=COALESCE(' + @CpActuals + ')
	AND ISNULL(cp.us_0_intl_1,wb.us_0_intl_1)=wb.us_0_intl_1
JOIN BudgetDB.dbo.products pd ON pd.hfm_product_code=COALESCE(' + @PdActuals + ')
	AND ISNULL(pd.us_0_intl_1,wb.us_0_intl_1)=wb.us_0_intl_1
JOIN BudgetDB.dbo.workbook_business_units wbbu ON wbbu.workbook_id=wb.workbook_id AND ISNULL(wbbu.bu_number,bu.bu_number)=bu.bu_number
JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=wb.workbook_id AND ISNULL(wbcp.company_number,cp.company_number)=cp.company_number
JOIN BudgetDB.dbo.workbook_departments wbdp ON wbdp.workbook_id=wb.workbook_id AND ISNULL(wbdp.dept_number,dp.dept_number)=dp.dept_number
JOIN BudgetDB.dbo.workbook_locations wblc ON wblc.workbook_id=wb.workbook_id AND ISNULL(wblc.location_number,lc.location_number)=lc.location_number
JOIN BudgetDB.dbo.workbook_products wbpd ON wbpd.workbook_id=wb.workbook_id AND ISNULL(wbpd.hfm_product_code,pd.hfm_product_code)=pd.hfm_product_code
JOIN BudgetDB.dbo.workbook_teams wbtm ON wbtm.workbook_id=wb.workbook_id AND ISNULL(wbtm.hfm_team_code,tm.hfm_team_code)=tm.hfm_team_code
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=bu.bu_number AND dv.dept_number=dp.dept_number
LEFT JOIN BudgetDB.dbo.pl_rollup plr ON plr.hfm_account_code=COALESCE(' + @GlActuals + ')
LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=COALESCE(' + @CrActuals + ',cp.currency_code)
	AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=plr.hfm_account_rollup'

EXEC sp_executesql @fullSQL
END

GO
