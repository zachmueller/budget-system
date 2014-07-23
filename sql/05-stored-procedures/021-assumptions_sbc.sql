USE BudgetDB
GO

IF OBJECT_ID('dbo.assumptions_commission', 'P') IS NOT NULL
	DROP PROCEDURE dbo.assumptions_commission
GO


CREATE PROCEDURE dbo.assumptions_sbc
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
SELECT NULL [company_name], NULL [bu_name],NULL [dept_name],NULL [team_name],NULL [location_name],NULL [exp_item]
	,NULL [Month 1],NULL [Month 2],NULL [Month 3],NULL [Month 4],NULL [Month 5],NULL [Month 6],NULL [Month 7],NULL [Month 8],NULL [Month 9]
	,NULL [Month 10],NULL [Month 11],NULL [Month 12],NULL [Month 13],NULL [Month 14],NULL [Month 15],NULL [Month 16],NULL [Month 17],NULL [Month 18]
	,NULL [Month 19],NULL [Month 20],NULL [Month 21],NULL [Month 22],NULL [Month 23],NULL [Month 24],NULL [Month 25],NULL [Month 26],NULL [Month 27]
	,NULL [Month 28],NULL [Month 29],NULL [Month 30],NULL [Month 31],NULL [Month 32],NULL [Month 33],NULL [Month 34],NULL [Month 35],NULL [Month 36]
END

ELSE

BEGIN	--	build dynamic SQL query to select out currency-converted data
	--	include both Stock Based Comp expense and the related Payroll Taxes
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
SELECT cp.company_name,bu.bu_name,dp.dept_name,tm.team_name,lc.location_name
	,pl.pl_item + '' - '' + pl.category_code [exp_item]
	,sbc.[Month 1]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 1] END*ISNULL(pt.[Month 1],dpt.[Month 1]) [Month 1]
	,sbc.[Month 2]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 2] END*ISNULL(pt.[Month 2],dpt.[Month 2]) [Month 2]
	,sbc.[Month 3]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 3] END*ISNULL(pt.[Month 3],dpt.[Month 3]) [Month 3]
	,sbc.[Month 4]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 4] END*ISNULL(pt.[Month 4],dpt.[Month 4]) [Month 4]
	,sbc.[Month 5]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 5] END*ISNULL(pt.[Month 5],dpt.[Month 5]) [Month 5]
	,sbc.[Month 6]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 6] END*ISNULL(pt.[Month 6],dpt.[Month 6]) [Month 6]
	,sbc.[Month 7]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 7] END*ISNULL(pt.[Month 7],dpt.[Month 7]) [Month 7]
	,sbc.[Month 8]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 8] END*ISNULL(pt.[Month 8],dpt.[Month 8]) [Month 8]
	,sbc.[Month 9]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 9] END*ISNULL(pt.[Month 9],dpt.[Month 9]) [Month 9]
	,sbc.[Month 10]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 10] END*ISNULL(pt.[Month 10],dpt.[Month 10]) [Month 10]
	,sbc.[Month 11]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 11] END*ISNULL(pt.[Month 11],dpt.[Month 11]) [Month 11]
	,sbc.[Month 12]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 12] END*ISNULL(pt.[Month 12],dpt.[Month 12]) [Month 12]
	,sbc.[Month 13]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 13] END*ISNULL(pt.[Month 13],dpt.[Month 13]) [Month 13]
	,sbc.[Month 14]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 14] END*ISNULL(pt.[Month 14],dpt.[Month 14]) [Month 14]
	,sbc.[Month 15]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 15] END*ISNULL(pt.[Month 15],dpt.[Month 15]) [Month 15]
	,sbc.[Month 16]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 16] END*ISNULL(pt.[Month 16],dpt.[Month 16]) [Month 16]
	,sbc.[Month 17]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 17] END*ISNULL(pt.[Month 17],dpt.[Month 17]) [Month 17]
	,sbc.[Month 18]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 18] END*ISNULL(pt.[Month 18],dpt.[Month 18]) [Month 18]
	,sbc.[Month 19]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 19] END*ISNULL(pt.[Month 19],dpt.[Month 19]) [Month 19]
	,sbc.[Month 20]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 20] END*ISNULL(pt.[Month 20],dpt.[Month 20]) [Month 20]
	,sbc.[Month 21]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 21] END*ISNULL(pt.[Month 21],dpt.[Month 21]) [Month 21]
	,sbc.[Month 22]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 22] END*ISNULL(pt.[Month 22],dpt.[Month 22]) [Month 22]
	,sbc.[Month 23]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 23] END*ISNULL(pt.[Month 23],dpt.[Month 23]) [Month 23]
	,sbc.[Month 24]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 24] END*ISNULL(pt.[Month 24],dpt.[Month 24]) [Month 24]
	,sbc.[Month 25]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 25] END*ISNULL(pt.[Month 25],dpt.[Month 25]) [Month 25]
	,sbc.[Month 26]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 26] END*ISNULL(pt.[Month 26],dpt.[Month 26]) [Month 26]
	,sbc.[Month 27]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 27] END*ISNULL(pt.[Month 27],dpt.[Month 27]) [Month 27]
	,sbc.[Month 28]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 28] END*ISNULL(pt.[Month 28],dpt.[Month 28]) [Month 28]
	,sbc.[Month 29]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 29] END*ISNULL(pt.[Month 29],dpt.[Month 29]) [Month 29]
	,sbc.[Month 30]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 30] END*ISNULL(pt.[Month 30],dpt.[Month 30]) [Month 30]
	,sbc.[Month 31]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 31] END*ISNULL(pt.[Month 31],dpt.[Month 31]) [Month 31]
	,sbc.[Month 32]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 32] END*ISNULL(pt.[Month 32],dpt.[Month 32]) [Month 32]
	,sbc.[Month 33]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 33] END*ISNULL(pt.[Month 33],dpt.[Month 33]) [Month 33]
	,sbc.[Month 34]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 34] END*ISNULL(pt.[Month 34],dpt.[Month 34]) [Month 34]
	,sbc.[Month 35]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 35] END*ISNULL(pt.[Month 35],dpt.[Month 35]) [Month 35]
	,sbc.[Month 36]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 36] END*ISNULL(pt.[Month 36],dpt.[Month 36]) [Month 36]
' + '
FROM BudgetDB.dbo.calculation_table_sbc sbc
LEFT JOIN BudgetDB.dbo.calculation_table_salary_payroll_taxes pt ON pt.bu_number=sbc.bu_number
	AND pt.scenario_id=sbc.scenario_id AND pt.company_number=sbc.company_number
LEFT JOIN BudgetDB.dbo.calculation_table_salary_payroll_taxes dpt ON dpt.bu_number IS NULL
	AND dpt.scenario_id=sbc.scenario_id AND dpt.company_number=sbc.company_number
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name=''Forecast'' AND sn.scenario_id=sbc.scenario_id
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=sbc.bu_number AND dv.dept_number=sbc.dept_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=ISNULL(pt.hfm_account_code,dpt.hfm_account_code)
	AND pl.category_code=dv.category_code
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=sbc.company_number
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=sbc.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=sbc.bu_number
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=sbc.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=sbc.location_number
LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(sbc.currency_code,cp.currency_code)
	AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL
JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=' + CAST(@wbID AS NVARCHAR) + '
	AND ISNULL(wb.us_0_intl_1,'''')=ISNULL(cp.us_0_intl_1,'''')
JOIN BudgetDB.dbo.workbook_business_units wbbu ON wbbu.workbook_id=wb.workbook_id
	AND ISNULL(wbbu.bu_number,sbc.bu_number)=sbc.bu_number
	AND COALESCE(bu.us_0_intl_1,wb.us_0_intl_1,'''')=COALESCE(wb.us_0_intl_1,'''')
JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=wb.workbook_id
	AND ISNULL(wbcp.company_number,sbc.company_number)=sbc.company_number
	AND COALESCE(cp.us_0_intl_1,wb.us_0_intl_1,'''')=COALESCE(wb.us_0_intl_1,'''')
JOIN BudgetDB.dbo.workbook_departments wbdp ON wbdp.workbook_id=wb.workbook_id
	AND ISNULL(wbdp.dept_number,sbc.dept_number)=sbc.dept_number
	AND COALESCE(dp.us_0_intl_1,wb.us_0_intl_1,'''')=COALESCE(wb.us_0_intl_1,'''')
JOIN BudgetDB.dbo.workbook_locations wblc ON wblc.workbook_id=wb.workbook_id
	AND ISNULL(wblc.location_number,sbc.location_number)=sbc.location_number
	AND COALESCE(lc.us_0_intl_1,wb.us_0_intl_1,'''')=COALESCE(wb.us_0_intl_1,'''')
JOIN BudgetDB.dbo.workbook_teams wbtm ON wbtm.workbook_id=wb.workbook_id
	AND ISNULL(wbtm.hfm_team_code,sbc.hfm_team_code)=sbc.hfm_team_code
	AND COALESCE(tm.us_0_intl_1,wb.us_0_intl_1,'''')=COALESCE(wb.us_0_intl_1,'''')' + '
UNION
SELECT cp.company_name,bu.bu_name,dp.dept_name,tm.team_name,lc.location_name
	,pl.pl_item + '' - '' + pl.category_code [exp_item]
	,sbc.[Month 1]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 1] END [Month 1]
	,sbc.[Month 2]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 2] END [Month 2]
	,sbc.[Month 3]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 3] END [Month 3]
	,sbc.[Month 4]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 4] END [Month 4]
	,sbc.[Month 5]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 5] END [Month 5]
	,sbc.[Month 6]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 6] END [Month 6]
	,sbc.[Month 7]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 7] END [Month 7]
	,sbc.[Month 8]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 8] END [Month 8]
	,sbc.[Month 9]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 9] END [Month 9]
	,sbc.[Month 10]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 10] END [Month 10]
	,sbc.[Month 11]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 11] END [Month 11]
	,sbc.[Month 12]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 12] END [Month 12]
	,sbc.[Month 13]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 13] END [Month 13]
	,sbc.[Month 14]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 14] END [Month 14]
	,sbc.[Month 15]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 15] END [Month 15]
	,sbc.[Month 16]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 16] END [Month 16]
	,sbc.[Month 17]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 17] END [Month 17]
	,sbc.[Month 18]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 18] END [Month 18]
	,sbc.[Month 19]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 19] END [Month 19]
	,sbc.[Month 20]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 20] END [Month 20]
	,sbc.[Month 21]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 21] END [Month 21]
	,sbc.[Month 22]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 22] END [Month 22]
	,sbc.[Month 23]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 23] END [Month 23]
	,sbc.[Month 24]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 24] END [Month 24]
	,sbc.[Month 25]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 25] END [Month 25]
	,sbc.[Month 26]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 26] END [Month 26]
	,sbc.[Month 27]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 27] END [Month 27]
	,sbc.[Month 28]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 28] END [Month 28]
	,sbc.[Month 29]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 29] END [Month 29]
	,sbc.[Month 30]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 30] END [Month 30]
	,sbc.[Month 31]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 31] END [Month 31]
	,sbc.[Month 32]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 32] END [Month 32]
	,sbc.[Month 33]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 33] END [Month 33]
	,sbc.[Month 34]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 34] END [Month 34]
	,sbc.[Month 35]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 35] END [Month 35]
	,sbc.[Month 36]*CASE WHEN ISNULL(sbc.currency_code,cp.currency_code)=''' + @curr + ''' THEN 1 ELSE cr.[Month 36] END [Month 36]
FROM BudgetDB.dbo.calculation_table_sbc sbc
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name=''Forecast'' AND sn.scenario_id=sbc.scenario_id
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=sbc.bu_number AND dv.dept_number=sbc.dept_number
JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=sbc.hfm_account_code AND pl.category_code=dv.category_code
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=sbc.company_number
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_number=sbc.dept_number
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=sbc.bu_number
LEFT JOIN BudgetDB.dbo.teams tm ON tm.hfm_team_code=sbc.hfm_team_code
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_number=sbc.location_number
LEFT JOIN #TempMonthlyRates cr ON cr.from_currency=ISNULL(sbc.currency_code,cp.currency_code)
	AND cr.to_currency=''' + @curr + ''' AND cr.scenario_id IS NULL
JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=' + CAST(@wbID AS NVARCHAR) + '
	AND ISNULL(wb.us_0_intl_1,'''')=ISNULL(cp.us_0_intl_1,'''')
JOIN BudgetDB.dbo.workbook_business_units wbbu ON wbbu.workbook_id=wb.workbook_id
	AND ISNULL(wbbu.bu_number,sbc.bu_number)=sbc.bu_number
	AND COALESCE(bu.us_0_intl_1,wb.us_0_intl_1,'''')=COALESCE(wb.us_0_intl_1,'''')
JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=wb.workbook_id
	AND ISNULL(wbcp.company_number,sbc.company_number)=sbc.company_number
	AND COALESCE(cp.us_0_intl_1,wb.us_0_intl_1,'''')=COALESCE(wb.us_0_intl_1,'''')
JOIN BudgetDB.dbo.workbook_departments wbdp ON wbdp.workbook_id=wb.workbook_id
	AND ISNULL(wbdp.dept_number,sbc.dept_number)=sbc.dept_number
	AND COALESCE(dp.us_0_intl_1,wb.us_0_intl_1,'''')=COALESCE(wb.us_0_intl_1,'''')
JOIN BudgetDB.dbo.workbook_locations wblc ON wblc.workbook_id=wb.workbook_id
	AND ISNULL(wblc.location_number,sbc.location_number)=sbc.location_number
	AND COALESCE(lc.us_0_intl_1,wb.us_0_intl_1,'''')=COALESCE(wb.us_0_intl_1,'''')
JOIN BudgetDB.dbo.workbook_teams wbtm ON wbtm.workbook_id=wb.workbook_id
	AND ISNULL(wbtm.hfm_team_code,sbc.hfm_team_code)=sbc.hfm_team_code
	AND COALESCE(tm.us_0_intl_1,wb.us_0_intl_1,'''')=COALESCE(wb.us_0_intl_1,'''')
'

EXEC sp_executesql @fullSQL
END

GO
