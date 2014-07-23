USE BudgetDB
GO

IF OBJECT_ID('dbo.assumptions_percent_of_base', 'P') IS NOT NULL
	DROP PROCEDURE dbo.assumptions_percent_of_base
GO


CREATE PROCEDURE dbo.assumptions_percent_of_base
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
	SELECT NULL company_name, NULL [exp_item]
		,NULL [Month 1],NULL [Month 2],NULL [Month 3],NULL [Month 4],NULL [Month 5],NULL [Month 6]
		,NULL [Month 7],NULL [Month 8],NULL [Month 9],NULL [Month 10],NULL [Month 11],NULL [Month 12]
		,NULL [Month 13],NULL [Month 14],NULL [Month 15],NULL [Month 16],NULL [Month 17],NULL [Month 18]
		,NULL [Month 19],NULL [Month 20],NULL [Month 21],NULL [Month 22],NULL [Month 23],NULL [Month 24]
		,NULL [Month 25],NULL [Month 26],NULL [Month 27],NULL [Month 28],NULL [Month 29],NULL [Month 30]
		,NULL [Month 31],NULL [Month 32],NULL [Month 33],NULL [Month 34],NULL [Month 35],NULL [Month 36]
END

ELSE 

BEGIN	--	select out workbook related data
	SELECT DISTINCT cp.company_name, pl.pl_item [exp_item]
		,pb.[Month 1],pb.[Month 2],pb.[Month 3],pb.[Month 4],pb.[Month 5],pb.[Month 6]
		,pb.[Month 7],pb.[Month 8],pb.[Month 9],pb.[Month 10],pb.[Month 11],pb.[Month 12]
		,pb.[Month 13],pb.[Month 14],pb.[Month 15],pb.[Month 16],pb.[Month 17],pb.[Month 18]
		,pb.[Month 19],pb.[Month 20],pb.[Month 21],pb.[Month 22],pb.[Month 23],pb.[Month 24]
		,pb.[Month 25],pb.[Month 26],pb.[Month 27],pb.[Month 28],pb.[Month 29],pb.[Month 30]
		,pb.[Month 31],pb.[Month 32],pb.[Month 33],pb.[Month 34],pb.[Month 35],pb.[Month 36]
	FROM BudgetDB.dbo.calculation_table_percent_of_base pb
	JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=pb.scenario_id
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=@wbID
		AND ISNULL(wbcp.company_number,pb.company_number)=pb.company_number
	JOIN BudgetDB.dbo.companies cp ON cp.company_number=pb.company_number
		AND ISNULL(wb.us_0_intl_1,'')=ISNULL(cp.us_0_intl_1,'')
	LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.hfm_account_code=pb.hfm_account_code
END

GO
