USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_update_scenario_activate', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_update_scenario_activate
GO


CREATE PROCEDURE dbo.settings_update_scenario_activate
	@scenarioName NVARCHAR(256)
AS
/*
summary:	>
			Activates a frozen scenario by setting
			its archived_scenario value to 0.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-28
*/

SET NOCOUNT ON

--	check that scenario exists and is a frozen scenario
IF (SELECT COUNT(*) FROM BudgetDB.dbo.scenarios
	WHERE scenario_name=@scenarioName
	AND date_frozen IS NOT NULL) = 0
BEGIN
	SELECT 'Frozen scenario ''' + @scenarioName + ''' not found in the database.' o
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:settings_update_scenario_activate' AS VARBINARY(128))
SET CONTEXT_INFO @ci

BEGIN TRY
BEGIN TRANSACTION

--	activate the scenario
UPDATE BudgetDB.dbo.scenarios
SET archived_scenario=0
WHERE scenario_name=@scenarioName

COMMIT TRANSACTION

SELECT 'Successfully activated the scenario.' msg

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

END TRY

BEGIN CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

SELECT 'An error occurred in the database when trying to update the scenario:'
	+ CHAR(13)+CHAR(10) + ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
