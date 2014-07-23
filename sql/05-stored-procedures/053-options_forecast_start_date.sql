USE BudgetDB
GO

IF OBJECT_ID('dbo.options_forecast_start_date', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_forecast_start_date
GO


CREATE PROCEDURE dbo.options_forecast_start_date
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides the
			start date of Forecast scenario.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

SELECT CAST(start_date AS datetime) start_date
FROM BudgetDB.dbo.scenarios
WHERE scenario_name='Forecast'


GO
