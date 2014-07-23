USE BudgetDB
GO

IF OBJECT_ID('dbo.assumptions_expense_payroll_taxes', 'P') IS NOT NULL
	DROP PROCEDURE dbo.assumptions_expense_payroll_taxes
GO


CREATE PROCEDURE dbo.assumptions_expense_payroll_taxes
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
	SELECT NULL [company_name], NULL [exp_match],NULL [exp_item]
		,NULL [Month 1],NULL [Month 2],NULL [Month 3],NULL [Month 4],NULL [Month 5],NULL [Month 6],NULL [Month 7],NULL [Month 8],NULL [Month 9]
		,NULL [Month 10],NULL [Month 11],NULL [Month 12],NULL [Month 13],NULL [Month 14],NULL [Month 15],NULL [Month 16],NULL [Month 17],NULL [Month 18]
		,NULL [Month 19],NULL [Month 20],NULL [Month 21],NULL [Month 22],NULL [Month 23],NULL [Month 24],NULL [Month 25],NULL [Month 26],NULL [Month 27]
		,NULL [Month 28],NULL [Month 29],NULL [Month 30],NULL [Month 31],NULL [Month 32],NULL [Month 33],NULL [Month 34],NULL [Month 35],NULL [Month 36]
END

ELSE

BEGIN	--	select out workbook related data
	SELECT DISTINCT cp.company_name, pl.pl_item exp_match, pl.pl_item exp_item
		,pt.[Month 1],pt.[Month 2],pt.[Month 3],pt.[Month 4],pt.[Month 5],pt.[Month 6]
		,pt.[Month 7],pt.[Month 8],pt.[Month 9],pt.[Month 10],pt.[Month 11],pt.[Month 12]
		,pt.[Month 13],pt.[Month 14],pt.[Month 15],pt.[Month 16],pt.[Month 17],pt.[Month 18]
		,pt.[Month 19],pt.[Month 20],pt.[Month 21],pt.[Month 22],pt.[Month 23],pt.[Month 24]
		,pt.[Month 25],pt.[Month 26],pt.[Month 27],pt.[Month 28],pt.[Month 29],pt.[Month 30]
		,pt.[Month 31],pt.[Month 32],pt.[Month 33],pt.[Month 34],pt.[Month 35],pt.[Month 36]
	FROM BudgetDB.dbo.calculation_table_expense_payroll_taxes pt
	JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=pt.scenario_id
	LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=pt.company_number
	LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=pt.hfm_account_code
	LEFT JOIN BudgetDB.dbo.pl_items epl ON epl.hfm_account_code=pt.hfm_expense_code
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=wb.workbook_id
		AND ISNULL(wbcp.company_number,pt.company_number)=pt.company_number
		AND ISNULL(wb.us_0_intl_1,'')=ISNULL(cp.us_0_intl_1,'')
END

GO
