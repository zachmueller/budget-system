USE BudgetDB
GO

IF OBJECT_ID('dbo.options_forecast_workbooks', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_forecast_workbooks
GO


CREATE PROCEDURE dbo.options_forecast_workbooks
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all active forecasting
			workbooks.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

SELECT workbook_id, workbook_name
FROM BudgetDB.dbo.workbooks
WHERE output_only=0
AND active_workbook=1
ORDER BY workbook_name ASC

GO
