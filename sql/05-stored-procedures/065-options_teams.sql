USE BudgetDB
GO

IF OBJECT_ID('dbo.options_teams', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_teams
GO


CREATE PROCEDURE dbo.options_teams
	@wbID INT = 0
	,@usIntl BIT = NULL
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Teams, filtered
			down to only those that are relevant
			to a provided workbook ID.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check workbook ID provided
IF ( @wbID=0 )
BEGIN	--	include all Teams
	SELECT tm.hfm_team_code, tm.team_name, ISNULL(tm.team_consolidation,tm.team_name) team_consolidation
		,CASE WHEN tm.us_0_intl_1 IS NULL THEN 'Both' 
		ELSE CASE WHEN tm.us_0_intl_1=0 THEN 'US' ELSE 'INTL' END END us_intl
	FROM BudgetDB.dbo.teams tm
	WHERE tm.active_forecast_option=1
	AND COALESCE(tm.us_0_intl_1,@usIntl,'')=ISNULL(@usIntl,'')
	ORDER BY ISNULL(tm.team_consolidation,tm.team_name) ASC
END

ELSE

BEGIN	--	only include Teams selected in workbook
	SELECT tm.hfm_team_code, tm.team_name, ISNULL(tm.team_consolidation,tm.team_name) team_consolidation
		,CASE WHEN tm.us_0_intl_1 IS NULL THEN 'Both' 
		ELSE CASE WHEN tm.us_0_intl_1=0 THEN 'US' ELSE 'INTL' END END us_intl
	FROM BudgetDB.dbo.teams tm
	LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=@wbID
	JOIN BudgetDB.dbo.workbook_teams wbtm
	ON wbtm.workbook_id=@wbID AND ISNULL(wbtm.hfm_team_code,tm.hfm_team_code)=tm.hfm_team_code
	WHERE tm.active_forecast_option=1
	AND COALESCE(tm.us_0_intl_1,wb.us_0_intl_1,'')=ISNULL(wb.us_0_intl_1,'')
	ORDER BY ISNULL(tm.team_consolidation,tm.team_name) ASC
END

GO
