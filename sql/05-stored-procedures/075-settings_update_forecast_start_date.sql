USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_update_forecast_start_date', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_update_forecast_start_date
GO


CREATE PROCEDURE dbo.settings_update_forecast_start_date
	@newDate DATE
AS
/*
summary:	>
			Changes the live Forecast start
			date to the date input provided.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	update CONTEXT_INFO for trigger
DECLARE @t VARCHAR(10) = CONVERT(varchar(10), @newDate, 120)
DECLARE @ci VARBINARY(128) = CAST('sproc:settings_update_forecast_start_date'
	+ ';New Date:' + @t AS VARBINARY(128))
SET CONTEXT_INFO @ci

--	update scenarios table to reflect new date
UPDATE BudgetDB.dbo.scenarios
SET start_date=@newDate
WHERE scenario_name='Forecast'

--	create new Actuals table(s) in HFM_ActualsDB, if needed
DECLARE @yr INT
SET @yr = YEAR(DATEADD(m,11,@newDate))
EXEC HFM_ActualsDB.dbo.create_actuals_table @yr
SET @yr = YEAR(DATEADD(m,23,@newDate))
EXEC HFM_ActualsDB.dbo.create_actuals_table @yr
SET @yr = YEAR(DATEADD(m,35,@newDate))
EXEC HFM_ActualsDB.dbo.create_actuals_table @yr

--	prompt user about successful update
SELECT 'Successfully updated the database.' o

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

GO
