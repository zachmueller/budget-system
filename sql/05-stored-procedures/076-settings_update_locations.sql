USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_update_locations', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_update_locations
GO


CREATE PROCEDURE dbo.settings_update_locations
	@uploadInput settings_upload_locations READONLY
AS
/*
summary:	>
			Uploads changes to be made to
			the dbo.locations table and applies
			them (INSERT or UPDATE) as needed.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check that all names are unique
IF (SELECT COUNT(*)-COUNT(DISTINCT location_name)
	FROM @uploadInput
	WHERE location_name IS NOT NULL) > 0
BEGIN
	SELECT 'Please ensure all location_names are unique then try uploading again.' o
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:settings_update_locations' AS VARBINARY(128))
SET CONTEXT_INFO @ci


BEGIN TRY
BEGIN TRANSACTION

--	merge uploadInput with database table
MERGE BudgetDB.dbo.locations lc
USING @uploadInput ui
ON ui.location_number=lc.location_number
WHEN MATCHED THEN
	UPDATE SET lc.location_name=ui.location_name,lc.us_0_intl_1=ui.us_0_intl_1
		,lc.active_forecast_option=ui.active_forecast_option
WHEN NOT MATCHED BY TARGET THEN
	INSERT (location_number, location_name, real_location
		,active_forecast_option, us_0_intl_1)
	VALUES (ui.location_number, ui.location_name, ui.real_location
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
