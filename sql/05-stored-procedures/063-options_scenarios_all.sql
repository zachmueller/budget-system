USE BudgetDB
GO

IF OBJECT_ID('dbo.options_scenarios_all', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_scenarios_all
GO


CREATE PROCEDURE dbo.options_scenarios_all
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all scenarios, including
			the live Forecast scenario.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

SELECT scenario_name, date_frozen
	,archived_scenario, scenario_id
FROM BudgetDB.dbo.scenarios
WHERE rev_scenario=0
AND scenario_name<>'Actual'

GO
