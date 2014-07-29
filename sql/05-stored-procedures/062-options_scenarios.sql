USE BudgetDB
GO

IF OBJECT_ID('dbo.options_scenarios', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_scenarios
GO


CREATE PROCEDURE dbo.options_scenarios
	@usIntl BIT
	,@cons BIT = NULL
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all frozen scenarios.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
- version 2:
		Modification: Added WHERE clause to filter out archived scenarios
		Author: Zach Mueller
		Date: 2014-07-28
*/

SET NOCOUNT ON

IF ( @cons IS NULL )
BEGIN	--	include only US or INTL scenarios
	SELECT scenario_name, date_frozen date_saved
		,archived_scenario
	FROM BudgetDB.dbo.scenarios
	WHERE date_frozen IS NOT NULL
	AND us_0_intl_1=@usIntl
	AND archived_scenario=0
END
ELSE
BEGIN	--	include only Consolidated scenarios
	SELECT scenario_name, scenario_id, date_frozen
		,CASE WHEN us_0_intl_1=0 THEN 'US' ELSE 'INTL' END us_intl
	FROM BudgetDB.dbo.scenarios
	WHERE date_frozen IS NOT NULL
	AND us_0_intl_1 IS NOT NULL
	AND archived_scenario=0
END

GO
