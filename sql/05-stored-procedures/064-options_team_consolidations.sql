USE BudgetDB
GO

IF OBJECT_ID('dbo.options_team_consolidations', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_team_consolidations
GO


CREATE PROCEDURE dbo.options_team_consolidations
	@usIntl BIT = NULL
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Team Consolidations, filtered
			down to only those that are relevant
			to a provided workbook ID.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

SELECT DISTINCT ISNULL(tm.team_consolidation,tm.team_name) team_consolidation
FROM BudgetDB.dbo.teams tm
WHERE tm.active_forecast_option=1
AND COALESCE(tm.us_0_intl_1,@usIntl,'')=ISNULL(@usIntl,'')
ORDER BY ISNULL(tm.team_consolidation,tm.team_name) ASC

GO
