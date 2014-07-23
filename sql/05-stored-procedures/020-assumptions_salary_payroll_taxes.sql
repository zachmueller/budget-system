USE BudgetDB
GO

IF OBJECT_ID('dbo.assumptions_salary_payroll_taxes', 'P') IS NOT NULL
	DROP PROCEDURE dbo.assumptions_salary_payroll_taxes
GO


CREATE PROCEDURE dbo.assumptions_salary_payroll_taxes
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
	SELECT NULL [company_name], NULL [bu_name],NULL [exp_item]
		,NULL [Month 1],NULL [Month 2],NULL [Month 3],NULL [Month 4],NULL [Month 5],NULL [Month 6],NULL [Month 7],NULL [Month 8],NULL [Month 9]
		,NULL [Month 10],NULL [Month 11],NULL [Month 12],NULL [Month 13],NULL [Month 14],NULL [Month 15],NULL [Month 16],NULL [Month 17],NULL [Month 18]
		,NULL [Month 19],NULL [Month 20],NULL [Month 21],NULL [Month 22],NULL [Month 23],NULL [Month 24],NULL [Month 25],NULL [Month 26],NULL [Month 27]
		,NULL [Month 28],NULL [Month 29],NULL [Month 30],NULL [Month 31],NULL [Month 32],NULL [Month 33],NULL [Month 34],NULL [Month 35],NULL [Month 36]
END

ELSE

BEGIN	--	select out workbook related data
	SELECT DISTINCT cp.company_name, bu.bu_name, ISNULL(pl.pl_item,dpl.pl_item) exp_item
		,COALESCE(pt.[Month 1],dpt.[Month 1]) [Month 1]
		,COALESCE(pt.[Month 2],dpt.[Month 2]) [Month 2]
		,COALESCE(pt.[Month 3],dpt.[Month 3]) [Month 3]
		,COALESCE(pt.[Month 4],dpt.[Month 4]) [Month 4]
		,COALESCE(pt.[Month 5],dpt.[Month 5]) [Month 5]
		,COALESCE(pt.[Month 6],dpt.[Month 6]) [Month 6]
		,COALESCE(pt.[Month 7],dpt.[Month 7]) [Month 7]
		,COALESCE(pt.[Month 8],dpt.[Month 8]) [Month 8]
		,COALESCE(pt.[Month 9],dpt.[Month 9]) [Month 9]
		,COALESCE(pt.[Month 10],dpt.[Month 10]) [Month 10]
		,COALESCE(pt.[Month 11],dpt.[Month 11]) [Month 11]
		,COALESCE(pt.[Month 12],dpt.[Month 12]) [Month 12]
		,COALESCE(pt.[Month 13],dpt.[Month 13]) [Month 13]
		,COALESCE(pt.[Month 14],dpt.[Month 14]) [Month 14]
		,COALESCE(pt.[Month 15],dpt.[Month 15]) [Month 15]
		,COALESCE(pt.[Month 16],dpt.[Month 16]) [Month 16]
		,COALESCE(pt.[Month 17],dpt.[Month 17]) [Month 17]
		,COALESCE(pt.[Month 18],dpt.[Month 18]) [Month 18]
		,COALESCE(pt.[Month 19],dpt.[Month 19]) [Month 19]
		,COALESCE(pt.[Month 20],dpt.[Month 20]) [Month 20]
		,COALESCE(pt.[Month 21],dpt.[Month 21]) [Month 21]
		,COALESCE(pt.[Month 22],dpt.[Month 22]) [Month 22]
		,COALESCE(pt.[Month 23],dpt.[Month 23]) [Month 23]
		,COALESCE(pt.[Month 24],dpt.[Month 24]) [Month 24]
		,COALESCE(pt.[Month 25],dpt.[Month 25]) [Month 25]
		,COALESCE(pt.[Month 26],dpt.[Month 26]) [Month 26]
		,COALESCE(pt.[Month 27],dpt.[Month 27]) [Month 27]
		,COALESCE(pt.[Month 28],dpt.[Month 28]) [Month 28]
		,COALESCE(pt.[Month 29],dpt.[Month 29]) [Month 29]
		,COALESCE(pt.[Month 30],dpt.[Month 30]) [Month 30]
		,COALESCE(pt.[Month 31],dpt.[Month 31]) [Month 31]
		,COALESCE(pt.[Month 32],dpt.[Month 32]) [Month 32]
		,COALESCE(pt.[Month 33],dpt.[Month 33]) [Month 33]
		,COALESCE(pt.[Month 34],dpt.[Month 34]) [Month 34]
		,COALESCE(pt.[Month 35],dpt.[Month 35]) [Month 35]
		,COALESCE(pt.[Month 36],dpt.[Month 36]) [Month 36]
	FROM BudgetDB.dbo.business_units bu
	LEFT JOIN BudgetDB.dbo.calculation_table_salary_payroll_taxes pt ON pt.bu_number=bu.bu_number
	LEFT JOIN BudgetDB.dbo.calculation_table_salary_payroll_taxes dpt ON dpt.bu_number IS NULL
	JOIN BudgetDB.dbo.companies cp ON cp.company_number=ISNULL(pt.company_number,dpt.company_number)
	LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=pt.hfm_account_code
	LEFT JOIN BudgetDB.dbo.pl_items dpl ON dpl.hfm_account_code=dpt.hfm_account_code
	JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast'
	AND sn.scenario_id=ISNULL(pt.scenario_id,dpt.scenario_id)
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
		AND ISNULL(wb.us_0_intl_1,'')=ISNULL(cp.us_0_intl_1,'')
	JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=wb.workbook_id
		AND COALESCE(wbcp.company_number,pt.company_number,dpt.company_number)
		=ISNULL(pt.company_number,dpt.company_number)
	JOIN BudgetDB.dbo.workbook_business_units wbbu ON wbbu.workbook_id=wb.workbook_id
		AND COALESCE(wbbu.bu_number,bu.bu_number)=bu.bu_number
	WHERE bu.active_forecast_option=1
END

GO
