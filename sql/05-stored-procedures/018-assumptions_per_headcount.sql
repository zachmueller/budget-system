USE BudgetDB
GO

IF OBJECT_ID('dbo.assumptions_per_headcount', 'P') IS NOT NULL
	DROP PROCEDURE dbo.assumptions_per_headcount
GO


CREATE PROCEDURE dbo.assumptions_per_headcount
	@wbID INT = 0
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
SELECT NULL company_name, NULL [exp_item]
	,NULL [Month 1],NULL [Month 2],NULL [Month 3],NULL [Month 4],NULL [Month 5],NULL [Month 6]
	,NULL [Month 7],NULL [Month 8],NULL [Month 9],NULL [Month 10],NULL [Month 11],NULL [Month 12]
	,NULL [Month 13],NULL [Month 14],NULL [Month 15],NULL [Month 16],NULL [Month 17],NULL [Month 18]
	,NULL [Month 19],NULL [Month 20],NULL [Month 21],NULL [Month 22],NULL [Month 23],NULL [Month 24]
	,NULL [Month 25],NULL [Month 26],NULL [Month 27],NULL [Month 28],NULL [Month 29],NULL [Month 30]
	,NULL [Month 31],NULL [Month 32],NULL [Month 33],NULL [Month 34],NULL [Month 35],NULL [Month 36]
END

ELSE 

BEGIN	--	build dynamic SQL query to download currency-converted relevant data
	DECLARE @startDate DATE = (SELECT TOP 1 start_date FROM BudgetDB.dbo.scenarios WHERE scenario_name='Forecast')
	DECLARE @loopCounter INT = 0
		,@currencyOut NVARCHAR(MAX) = ''
		,@currencyIn NVARCHAR(MAX) = ''
		,@currencyStartDate NVARCHAR(10) = CONVERT(NVARCHAR(10),@startDate,120)	--Date Format: yyyy-mm-dd
		,@currencyEndDate NVARCHAR(10) = CONVERT(NVARCHAR(10),DATEADD(m,35,@startDate),120)	--Date Format: yyyy-mm-dd
		,@currencySQL NVARCHAR(MAX)
		,@fullSQL NVARCHAR(MAX)

	WHILE @loopCounter < 36
	BEGIN
		--	currency pivot table strings
		SET @currencyOut = @currencyOut + ',[' + CAST(CAST(DATEADD(m,@loopCounter,@startDate) AS DATE) AS NVARCHAR)
			+ '] AS [Month ' + CAST((@loopCounter + 1) AS NVARCHAR) + ']'
		SET @currencyIn = @currencyIn + '[' + CAST(CAST(DATEADD(m,@loopCounter,@startDate) AS DATE) AS NVARCHAR) + '],'
		SET @loopCounter = @loopCounter + 1
	END
	
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

SET @fullSQL = @currencySQL + '
SELECT DISTINCT cp.company_name, pl.pl_item [exp_item]
	,ph.[Month 1]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 1] END [Month 1]
	,ph.[Month 2]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 2] END [Month 2]
	,ph.[Month 3]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 3] END [Month 3]
	,ph.[Month 4]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 4] END [Month 4]
	,ph.[Month 5]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 5] END [Month 5]
	,ph.[Month 6]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 6] END [Month 6]
	,ph.[Month 7]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 7] END [Month 7]
	,ph.[Month 8]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 8] END [Month 8]
	,ph.[Month 9]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 9] END [Month 9]
	,ph.[Month 10]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 10] END [Month 10]
	,ph.[Month 11]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 11] END [Month 11]
	,ph.[Month 12]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 12] END [Month 12]
	,ph.[Month 13]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 13] END [Month 13]
	,ph.[Month 14]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 14] END [Month 14]
	,ph.[Month 15]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 15] END [Month 15]
	,ph.[Month 16]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 16] END [Month 16]
	,ph.[Month 17]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 17] END [Month 17]
	,ph.[Month 18]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 18] END [Month 18]
	,ph.[Month 19]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 19] END [Month 19]
	,ph.[Month 20]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 20] END [Month 20]
	,ph.[Month 21]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 21] END [Month 21]
	,ph.[Month 22]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 22] END [Month 22]
	,ph.[Month 23]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 23] END [Month 23]
	,ph.[Month 24]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 24] END [Month 24]
	,ph.[Month 25]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 25] END [Month 25]
	,ph.[Month 26]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 26] END [Month 26]
	,ph.[Month 27]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 27] END [Month 27]
	,ph.[Month 28]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 28] END [Month 28]
	,ph.[Month 29]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 29] END [Month 29]
	,ph.[Month 30]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 30] END [Month 30]
	,ph.[Month 31]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 31] END [Month 31]
	,ph.[Month 32]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 32] END [Month 32]
	,ph.[Month 33]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 33] END [Month 33]
	,ph.[Month 34]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 34] END [Month 34]
	,ph.[Month 35]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 35] END [Month 35]
	,ph.[Month 36]*CASE WHEN ISNULL(ph.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 36] END [Month 36]
FROM BudgetDB.dbo.calculation_table_per_headcount_assumptions ph
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name=''Forecast'' AND sn.scenario_id=ph.scenario_id
JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=' + CAST(@wbID AS NVARCHAR) + '
JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=wb.workbook_id
	AND ISNULL(wbcp.company_number,ph.company_number)=ph.company_number
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=ph.company_number
	AND ISNULL(wb.us_0_intl_1,'''')=ISNULL(cp.us_0_intl_1,'''')
LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(ph.currency_code,cp.currency_code)
	AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=ph.hfm_account_code
'

EXEC sp_executesql @fullSQL
END

GO
