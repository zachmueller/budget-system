USE BudgetDB
GO

IF OBJECT_ID('dbo.assumptions_bonus_payout', 'P') IS NOT NULL
	DROP PROCEDURE dbo.assumptions_bonus_payout
GO


CREATE PROCEDURE dbo.assumptions_bonus_payout
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

SELECT bp.[Month 1],bp.[Month 2],bp.[Month 3],bp.[Month 4],bp.[Month 5],bp.[Month 6]
	,bp.[Month 7],bp.[Month 8],bp.[Month 9],bp.[Month 10],bp.[Month 11],bp.[Month 12]
	,bp.[Month 13],bp.[Month 14],bp.[Month 15],bp.[Month 16],bp.[Month 17],bp.[Month 18]
	,bp.[Month 19],bp.[Month 20],bp.[Month 21],bp.[Month 22],bp.[Month 23],bp.[Month 24]
	,bp.[Month 25],bp.[Month 26],bp.[Month 27],bp.[Month 28],bp.[Month 29],bp.[Month 30]
	,bp.[Month 31],bp.[Month 32],bp.[Month 33],bp.[Month 34],bp.[Month 35],bp.[Month 36]
FROM BudgetDB.dbo.calculation_table_bonus_payout_pct bp
JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name='Forecast' AND sn.scenario_id=bp.scenario_id

GO
