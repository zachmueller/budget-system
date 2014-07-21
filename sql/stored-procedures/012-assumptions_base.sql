USE BudgetDB
GO

IF OBJECT_ID('dbo.assumptions_base', 'P') IS NOT NULL
	DROP PROCEDURE dbo.assumptions_base
GO


CREATE PROCEDURE dbo.assumptions_base
	@wbID INT = 0
	,@curr NCHAR(3) = 'USD'
AS
/*
summary:	>
			Download into Excel a local copy of Master Assumptions
			data relevant to each workbook, used to locally
			calculate a full P&L. Set up as a dynamic SQL query
			to handle the currency PIVOTing necessary
			to convert from each record's local currency.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-21
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

--	test whether returning data is relevant to the provided workbook ID
--	Invalid workbook IDs and Output Only workbooks do not need to download data
IF (ISNULL((SELECT TOP 1 1-output_only
	FROM BudgetDB.dbo.workbooks
	WHERE workbook_id=@wbID),0)) = 0
BEGIN	--	select out NULL values, though keep the same structure to not interfere with the Excel layout
	SELECT NULL [company_name], NULL [bu_name],NULL [dept_name],NULL [team_consolidation],NULL [location_name],NULL [job_title],NULL [exp_item]
	,NULL [Month 1],NULL [Month 2],NULL [Month 3],NULL [Month 4],NULL [Month 5],NULL [Month 6],NULL [Month 7],NULL [Month 8],NULL [Month 9]
	,NULL [Month 10],NULL [Month 11],NULL [Month 12],NULL [Month 13],NULL [Month 14],NULL [Month 15],NULL [Month 16],NULL [Month 17],NULL [Month 18]
	,NULL [Month 19],NULL [Month 20],NULL [Month 21],NULL [Month 22],NULL [Month 23],NULL [Month 24],NULL [Month 25],NULL [Month 26],NULL [Month 27]
	,NULL [Month 28],NULL [Month 29],NULL [Month 30],NULL [Month 31],NULL [Month 32],NULL [Month 33],NULL [Month 34],NULL [Month 35],NULL [Month 36]
END

ELSE

BEGIN	--	start building dynamic SQL query to select out relevant data
	DECLARE @startDate DATE = (
		SELECT TOP 1 start_date
		FROM BudgetDB.dbo.scenarios
		WHERE scenario_name='Forecast')
	
	--	create variables necessary for dynamically pulling in currency rates
	DECLARE @loopCounter INT = 0
		,@currencyOut NVARCHAR(MAX) = ''
		,@currencyIn NVARCHAR(MAX) = ''
		,@currencyStartDate NVARCHAR(10) = CONVERT(NVARCHAR(10),@startDate,120)	--Date Format: yyyy-mm-dd
		,@currencyEndDate NVARCHAR(10) = CONVERT(NVARCHAR(10),DATEADD(m,35,@startDate),120)	--Date Format: yyyy-mm-dd
		,@currencySQL NVARCHAR(MAX)
		,@fullSQL NVARCHAR(MAX)

	--	loop through 36 months and build out currency query
	WHILE @loopCounter < 36
	BEGIN
		--	currency pivot table strings
		SET @currencyOut = @currencyOut + ',[' + CAST(CAST(DATEADD(m,@loopCounter,@startDate) AS DATE) AS NVARCHAR)
			+ '] AS [Month ' + CAST((@loopCounter + 1) AS NVARCHAR) + ']'
		SET @currencyIn = @currencyIn + '[' + CAST(CAST(DATEADD(m,@loopCounter,@startDate) AS DATE) AS NVARCHAR) + '],'
		SET @loopCounter = @loopCounter + 1
	END
	
	--	trim off first comma
	SET @currencyIn = LEFT(@currencyIn,LEN(@currencyIn)-1)
	
	--	put together complete currency query
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

SET @fullSQL = @currencySQL + '
SELECT cp.[company_name],bu.[bu_name],dp.[dept_name],ISNULL(tm.team_consolidation,tm.team_name) [team_consolidation]
	,lc.[location_name],jt.[job_title], pl.pl_item + '' - '' + pl.category_code [exp_item]
	,SUM(a.ft_pt_count*a.[Month 1]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 1] END)/SUM(a.ft_pt_count) [Month 1]
	,SUM(a.ft_pt_count*a.[Month 2]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 2] END)/SUM(a.ft_pt_count) [Month 2]
	,SUM(a.ft_pt_count*a.[Month 3]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 3] END)/SUM(a.ft_pt_count) [Month 3]
	,SUM(a.ft_pt_count*a.[Month 4]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 4] END)/SUM(a.ft_pt_count) [Month 4]
	,SUM(a.ft_pt_count*a.[Month 5]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 5] END)/SUM(a.ft_pt_count) [Month 5]
	,SUM(a.ft_pt_count*a.[Month 6]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 6] END)/SUM(a.ft_pt_count) [Month 6]
	,SUM(a.ft_pt_count*a.[Month 7]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 7] END)/SUM(a.ft_pt_count) [Month 7]
	,SUM(a.ft_pt_count*a.[Month 8]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 8] END)/SUM(a.ft_pt_count) [Month 8]
	,SUM(a.ft_pt_count*a.[Month 9]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 9] END)/SUM(a.ft_pt_count) [Month 9]
	,SUM(a.ft_pt_count*a.[Month 10]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 10] END)/SUM(a.ft_pt_count) [Month 10]
	,SUM(a.ft_pt_count*a.[Month 11]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 11] END)/SUM(a.ft_pt_count) [Month 11]
	,SUM(a.ft_pt_count*a.[Month 12]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 12] END)/SUM(a.ft_pt_count) [Month 12]
	,SUM(a.ft_pt_count*a.[Month 13]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 13] END)/SUM(a.ft_pt_count) [Month 13]
	,SUM(a.ft_pt_count*a.[Month 14]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 14] END)/SUM(a.ft_pt_count) [Month 14]
	,SUM(a.ft_pt_count*a.[Month 15]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 15] END)/SUM(a.ft_pt_count) [Month 15]
	,SUM(a.ft_pt_count*a.[Month 16]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 16] END)/SUM(a.ft_pt_count) [Month 16]
	,SUM(a.ft_pt_count*a.[Month 17]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 17] END)/SUM(a.ft_pt_count) [Month 17]
	,SUM(a.ft_pt_count*a.[Month 18]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 18] END)/SUM(a.ft_pt_count) [Month 18]
	,SUM(a.ft_pt_count*a.[Month 19]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 19] END)/SUM(a.ft_pt_count) [Month 19]
	,SUM(a.ft_pt_count*a.[Month 20]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 20] END)/SUM(a.ft_pt_count) [Month 20]
	,SUM(a.ft_pt_count*a.[Month 21]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 21] END)/SUM(a.ft_pt_count) [Month 21]
	,SUM(a.ft_pt_count*a.[Month 22]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 22] END)/SUM(a.ft_pt_count) [Month 22]
	,SUM(a.ft_pt_count*a.[Month 23]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 23] END)/SUM(a.ft_pt_count) [Month 23]
	,SUM(a.ft_pt_count*a.[Month 24]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 24] END)/SUM(a.ft_pt_count) [Month 24]
	,SUM(a.ft_pt_count*a.[Month 25]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 25] END)/SUM(a.ft_pt_count) [Month 25]
	,SUM(a.ft_pt_count*a.[Month 26]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 26] END)/SUM(a.ft_pt_count) [Month 26]
	,SUM(a.ft_pt_count*a.[Month 27]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 27] END)/SUM(a.ft_pt_count) [Month 27]
	,SUM(a.ft_pt_count*a.[Month 28]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 28] END)/SUM(a.ft_pt_count) [Month 28]
	,SUM(a.ft_pt_count*a.[Month 29]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 29] END)/SUM(a.ft_pt_count) [Month 29]
	,SUM(a.ft_pt_count*a.[Month 30]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 30] END)/SUM(a.ft_pt_count) [Month 30]
	,SUM(a.ft_pt_count*a.[Month 31]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 31] END)/SUM(a.ft_pt_count) [Month 31]
	,SUM(a.ft_pt_count*a.[Month 32]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 32] END)/SUM(a.ft_pt_count) [Month 32]
	,SUM(a.ft_pt_count*a.[Month 33]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 33] END)/SUM(a.ft_pt_count) [Month 33]
	,SUM(a.ft_pt_count*a.[Month 34]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 34] END)/SUM(a.ft_pt_count) [Month 34]
	,SUM(a.ft_pt_count*a.[Month 35]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 35] END)/SUM(a.ft_pt_count) [Month 35]
	,SUM(a.ft_pt_count*a.[Month 36]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 36] END)/SUM(a.ft_pt_count) [Month 36]
FROM BudgetDB.dbo.calculation_table_base a
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name=''Forecast'' AND sn.scenario_id=a.scenario_id
LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=' + CAST(@wbID AS NVARCHAR) + '
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
	AND ISNULL(wb.us_0_intl_1,'''')=ISNULL(cp.us_0_intl_1,'''')
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=a.bu_number
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=a.dept_number
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=a.location_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(a.currency_code,cp.currency_code)
	AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=a.hfm_account_code
GROUP BY cp.company_name, bu.bu_name,dp.dept_name,ISNULL(tm.team_consolidation,tm.team_name)
	,lc.location_name,jt.job_title,pl.pl_item + '' - '' + pl.category_code
UNION
--	include dummy job title salaries
SELECT cp.[company_name],bu.[bu_name],dp.[dept_name],ISNULL(tm.team_consolidation,tm.team_name) [team_consolidation]
	,lc.[location_name],jt.[job_title],pl.pl_item + '' - '' + pl.category_code [exp_item]
	,SUM(a.ft_pt_count*a.[Month 1]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 1] END)/SUM(a.ft_pt_count) [Month 1]
	,SUM(a.ft_pt_count*a.[Month 2]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 2] END)/SUM(a.ft_pt_count) [Month 2]
	,SUM(a.ft_pt_count*a.[Month 3]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 3] END)/SUM(a.ft_pt_count) [Month 3]
	,SUM(a.ft_pt_count*a.[Month 4]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 4] END)/SUM(a.ft_pt_count) [Month 4]
	,SUM(a.ft_pt_count*a.[Month 5]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 5] END)/SUM(a.ft_pt_count) [Month 5]
	,SUM(a.ft_pt_count*a.[Month 6]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 6] END)/SUM(a.ft_pt_count) [Month 6]
	,SUM(a.ft_pt_count*a.[Month 7]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 7] END)/SUM(a.ft_pt_count) [Month 7]
	,SUM(a.ft_pt_count*a.[Month 8]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 8] END)/SUM(a.ft_pt_count) [Month 8]
	,SUM(a.ft_pt_count*a.[Month 9]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 9] END)/SUM(a.ft_pt_count) [Month 9]
	,SUM(a.ft_pt_count*a.[Month 10]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 10] END)/SUM(a.ft_pt_count) [Month 10]
	,SUM(a.ft_pt_count*a.[Month 11]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 11] END)/SUM(a.ft_pt_count) [Month 11]
	,SUM(a.ft_pt_count*a.[Month 12]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 12] END)/SUM(a.ft_pt_count) [Month 12]
	,SUM(a.ft_pt_count*a.[Month 13]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 13] END)/SUM(a.ft_pt_count) [Month 13]
	,SUM(a.ft_pt_count*a.[Month 14]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 14] END)/SUM(a.ft_pt_count) [Month 14]
	,SUM(a.ft_pt_count*a.[Month 15]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 15] END)/SUM(a.ft_pt_count) [Month 15]
	,SUM(a.ft_pt_count*a.[Month 16]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 16] END)/SUM(a.ft_pt_count) [Month 16]
	,SUM(a.ft_pt_count*a.[Month 17]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 17] END)/SUM(a.ft_pt_count) [Month 17]
	,SUM(a.ft_pt_count*a.[Month 18]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 18] END)/SUM(a.ft_pt_count) [Month 18]
	,SUM(a.ft_pt_count*a.[Month 19]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 19] END)/SUM(a.ft_pt_count) [Month 19]
	,SUM(a.ft_pt_count*a.[Month 20]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 20] END)/SUM(a.ft_pt_count) [Month 20]
	,SUM(a.ft_pt_count*a.[Month 21]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 21] END)/SUM(a.ft_pt_count) [Month 21]
	,SUM(a.ft_pt_count*a.[Month 22]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 22] END)/SUM(a.ft_pt_count) [Month 22]
	,SUM(a.ft_pt_count*a.[Month 23]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 23] END)/SUM(a.ft_pt_count) [Month 23]
	,SUM(a.ft_pt_count*a.[Month 24]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 24] END)/SUM(a.ft_pt_count) [Month 24]
	,SUM(a.ft_pt_count*a.[Month 25]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 25] END)/SUM(a.ft_pt_count) [Month 25]
	,SUM(a.ft_pt_count*a.[Month 26]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 26] END)/SUM(a.ft_pt_count) [Month 26]
	,SUM(a.ft_pt_count*a.[Month 27]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 27] END)/SUM(a.ft_pt_count) [Month 27]
	,SUM(a.ft_pt_count*a.[Month 28]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 28] END)/SUM(a.ft_pt_count) [Month 28]
	,SUM(a.ft_pt_count*a.[Month 29]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 29] END)/SUM(a.ft_pt_count) [Month 29]
	,SUM(a.ft_pt_count*a.[Month 30]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 30] END)/SUM(a.ft_pt_count) [Month 30]
	,SUM(a.ft_pt_count*a.[Month 31]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 31] END)/SUM(a.ft_pt_count) [Month 31]
	,SUM(a.ft_pt_count*a.[Month 32]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 32] END)/SUM(a.ft_pt_count) [Month 32]
	,SUM(a.ft_pt_count*a.[Month 33]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 33] END)/SUM(a.ft_pt_count) [Month 33]
	,SUM(a.ft_pt_count*a.[Month 34]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 34] END)/SUM(a.ft_pt_count) [Month 34]
	,SUM(a.ft_pt_count*a.[Month 35]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 35] END)/SUM(a.ft_pt_count) [Month 35]
	,SUM(a.ft_pt_count*a.[Month 36]*CASE WHEN ISNULL(a.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 36] END)/SUM(a.ft_pt_count) [Month 36]
FROM BudgetDB.dbo.calculation_table_base a
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name=''Forecast'' AND sn.scenario_id=a.scenario_id
LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=' + CAST(@wbID AS NVARCHAR) + '
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=a.company_number
	AND ISNULL(wb.us_0_intl_1,'''')=ISNULL(cp.us_0_intl_1,'''')
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=a.bu_number
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=a.dept_number
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=a.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=a.location_number
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_id=a.job_id
LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(a.currency_code,cp.currency_code)
	AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=a.hfm_account_code
WHERE a.bu_number=''0000'' AND a.dept_number=''0000''
AND a.hfm_team_code=''000'' AND a.location_number=''000''
GROUP BY cp.company_name, bu.bu_name,dp.dept_name,ISNULL(tm.team_consolidation,tm.team_name)
	,lc.location_name,jt.job_title,pl.pl_item + '' - '' + pl.category_code
'

EXEC sp_executesql @fullSQL
END

GO
