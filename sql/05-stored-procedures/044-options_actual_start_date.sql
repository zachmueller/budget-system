USE BudgetDB
GO

IF OBJECT_ID('dbo.options_actual_start_date', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_actual_start_date
GO


CREATE PROCEDURE dbo.options_actual_start_date
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides the
			latest date of Actuals data that
			is currently in the database.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

SELECT CAST(start_date AS datetime) current_actuals_date
FROM BudgetDB.dbo.scenarios
WHERE scenario_name='Actual'

GO
