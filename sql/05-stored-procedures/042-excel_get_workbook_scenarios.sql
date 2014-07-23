USE BudgetDB
GO

IF OBJECT_ID('dbo.excel_get_workbook_scenarios', 'P') IS NOT NULL
	DROP PROCEDURE dbo.excel_get_workbook_scenarios
GO


CREATE PROCEDURE dbo.excel_get_workbook_scenarios
	@wbID INT = NULL
AS
/*
summary:	>
			Used to list out all available frozen
			scenarios in the database. When no
			workbook ID is provided, all active
			scneraios are returned (to fill the
			full list of scenarios). When a valid
			workbook ID is provided, include details
			about whether the scenario is selected
			for the workbook.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

--	check whether valid workbook ID provided
IF (SELECT TOP 1 us_0_intl_1
	FROM BudgetDB.dbo.workbooks
	WHERE workbook_id=@wbID
	) IS NULL
BEGIN	--	if invalid/NULL workbook ID, list all scenarios
	SELECT sn.scenario_name, sn.scenario_id, sn.date_frozen
		,CASE WHEN wbsn.scenario_id IS NOT NULL THEN 1
		ELSE 0 END wb_selected, NULL us_intl
	FROM BudgetDB.dbo.scenarios sn
	LEFT JOIN BudgetDB.dbo.workbook_scenarios wbsn
	ON wbsn.scenario_id=sn.scenario_id AND wbsn.workbook_id=@wbID
	WHERE sn.date_frozen IS NOT NULL AND sn.us_0_intl_1 IS NULL
	AND sn.archived_scenario=0
	ORDER BY sn.date_frozen DESC, sn.start_date DESC
END
ELSE
BEGIN	--	if valid workbook ID provided, identify scenarios selected for workbook
	SELECT sn.scenario_name, sn.scenario_id, sn.date_frozen
		,CASE WHEN wbsn.scenario_id IS NOT NULL THEN 1
			ELSE 0 END wb_selected
		--	Identify whether to fill the US, INTL, or Consolidated lists
		,CASE WHEN sn.us_0_intl_1=0 THEN 'US' 
			WHEN sn.us_0_intl_1=0 THEN 'INTL' ELSE 'Cons' END us_intl
	FROM BudgetDB.dbo.scenarios sn
	LEFT JOIN BudgetDB.dbo.workbook_scenarios wbsn
	ON wbsn.scenario_id=sn.scenario_id AND wbsn.workbook_id=@wbID
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	WHERE sn.date_frozen IS NOT NULL AND sn.archived_scenario=0
	AND ISNULL(sn.us_0_intl_1,wb.us_0_intl_1)=wb.us_0_intl_1
	ORDER BY sn.date_frozen DESC, sn.start_date DESC
END

GO
