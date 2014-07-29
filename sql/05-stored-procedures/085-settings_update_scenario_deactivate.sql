USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_update_scenario_deactivate', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_update_scenario_deactivate
GO


CREATE PROCEDURE dbo.settings_update_scenario_deactivate
	@scenarioName NVARCHAR(256)
AS
/*
summary:	>
			Deactivates a frozen scenario by setting
			its archived_scenario value to 1.
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
DECLARE @ci VARBINARY(128) = CAST('sproc:settings_update_scenario_deactivate' AS VARBINARY(128))
SET CONTEXT_INFO @ci

BEGIN TRY
BEGIN TRANSACTION

--	activate the scenario
UPDATE BudgetDB.dbo.scenarios
SET archived_scenario=1
WHERE scenario_name=@scenarioName

COMMIT TRANSACTION

SELECT 'Successfully deactivated the scenario.' msg

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
