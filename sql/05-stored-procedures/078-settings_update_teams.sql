USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_update_teams', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_update_teams
GO


CREATE PROCEDURE dbo.settings_update_teams
	@uploadInput settings_upload_teams READONLY
AS
/*
summary:	>
			Uploads changes to be made to
			the dbo.teams table and applies
			them (INSERT or UPDATE) as needed.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check that all names are unique
IF (SELECT COUNT(*)-COUNT(DISTINCT team_name)
	FROM @uploadInput
	WHERE team_name IS NOT NULL) > 0
BEGIN
	SELECT 'Please ensure all team_names are unique then try uploading again.' o
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:settings_update_teams' AS VARBINARY(128))
SET CONTEXT_INFO @ci


BEGIN TRY
BEGIN TRANSACTION

--	merge uploadInput with database table
MERGE BudgetDB.dbo.teams tm
USING @uploadInput ui
ON ui.hfm_team_code=tm.hfm_team_code
WHEN MATCHED THEN
	UPDATE SET tm.team_name=ui.team_name,tm.us_0_intl_1=ui.us_0_intl_1
		,tm.team_consolidation=ISNULL(ui.team_consolidation,ui.team_name)
		,tm.active_forecast_option=ui.active_forecast_option
WHEN NOT MATCHED BY TARGET THEN
	INSERT (hfm_team_code, team_name, team_consolidation
		,active_forecast_option, us_0_intl_1)
	VALUES (ui.hfm_team_code, ui.team_name, ui.team_consolidation
		,ui.active_forecast_option, ui.us_0_intl_1)
;

SELECT 'Database successfully updated.' o, 5 n
COMMIT TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

END TRY

BEGIN CATCH
--	rollback transaction
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

--	return error message to user
SELECT 'An error occurred in the database while attemping to update the database:' 
	+ CHAR(13)+CHAR(10) + ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
