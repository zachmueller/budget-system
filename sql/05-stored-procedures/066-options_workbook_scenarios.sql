USE BudgetDB
GO

IF OBJECT_ID('dbo.options_workbook_scenarios', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_workbook_scenarios
GO


CREATE PROCEDURE dbo.options_workbook_scenarios
	@wbID INT = 0
	,@pf INT = NULL		--	whether or not to include Pro Forma scenario name
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of scenarios relevant
			to a provided workbook ID.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	if Pro Forma chosen, return only scenario names, else return names and dates
IF ( @pf IS NOT NULL )
BEGIN
SELECT t.scenario_name
FROM (
	SELECT sn.scenario_name, 1 ob
	FROM BudgetDB.dbo.scenarios sn
	WHERE scenario_name IN ('Actual','Forecast')
	UNION ALL
	SELECT sn.scenario_name, 2 ob
	FROM BudgetDB.dbo.workbook_scenarios wbsn
	JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=wbsn.scenario_id
	WHERE wbsn.workbook_id=@wbID
	UNION ALL
	SELECT 'Pro Forma' scenario_name, 3 ob
) t
ORDER BY t.ob ASC
END

ELSE

BEGIN
SELECT t.scenario_name, CAST(t.start_date AS DATETIME) start_date
FROM (
	SELECT sn.scenario_name, sn.start_date, 1 ob
	FROM BudgetDB.dbo.scenarios sn
	WHERE scenario_name IN ('Actual','Forecast')
	UNION ALL
	SELECT sn.scenario_name, sn.start_date, 2 ob
	FROM BudgetDB.dbo.workbook_scenarios wbsn
	JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_id=wbsn.scenario_id
	WHERE wbsn.workbook_id=@wbID
) t
ORDER BY t.ob ASC
END

GO
