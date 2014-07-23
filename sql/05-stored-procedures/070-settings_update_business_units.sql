USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_update_business_units', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_update_business_units
GO


CREATE PROCEDURE dbo.settings_update_business_units
	@uploadInput settings_upload_business_units READONLY
AS
/*
summary:	>
			Uploads changes to be made to
			the dbo.business_units table and applies
			them (INSERT or UPDATE) as needed.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check that all names are unique
IF (SELECT COUNT(*)-COUNT(DISTINCT bu_name)
	FROM @uploadInput
	WHERE bu_name IS NOT NULL) > 0
BEGIN
	SELECT 'Please ensure all bu_names are unique then try uploading again.' o
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:settings_update_business_units' AS VARBINARY(128))
SET CONTEXT_INFO @ci


BEGIN TRY
BEGIN TRANSACTION
--	merge uploadInput with database table
MERGE BudgetDB.dbo.business_units bu
USING @uploadInput ui
ON ui.bu_number=bu.bu_number
WHEN MATCHED THEN
	UPDATE SET bu.bu_name=ui.bu_name,bu.us_0_intl_1=ui.us_0_intl_1
		,bu.active_forecast_option=ui.active_forecast_option
WHEN NOT MATCHED BY TARGET THEN
	INSERT (bu_number, bu_name, active_forecast_option
		,us_0_intl_1)
	VALUES (ui.bu_number, ui.bu_name, ui.active_forecast_option
		,ui.us_0_intl_1)
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
