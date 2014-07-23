USE BudgetDB
GO

IF OBJECT_ID('dbo.options_revenue_scenarios', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_revenue_scenarios
GO


CREATE PROCEDURE dbo.options_revenue_scenarios
	@include BIT = 0	--	input whether to include 'Inputs Tab' value in set
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Revenue scenarios.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

IF ( @include = 0 )
BEGIN	--	only select real Revenue scenarios
	SELECT scenario_name
	FROM BudgetDB.dbo.scenarios
	WHERE rev_scenario=1
END

ELSE

BEGIN	--	include 'Inputs Tab' value in addition to revenue scenarios
	SELECT scenario_name
	FROM BudgetDB.dbo.scenarios
	WHERE rev_scenario=1
	UNION ALL
	SELECT 'Inputs Tab' scenario_name
END

GO
