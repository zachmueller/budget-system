USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_update_departments', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_update_departments
GO


CREATE PROCEDURE dbo.settings_update_departments
	@uploadInput settings_upload_departments READONLY
AS
/*
summary:	>
			Uploads changes to be made to
			the dbo.departments table and applies
			them (INSERT or UPDATE) as needed.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check that all names are unique
IF (SELECT COUNT(*)-COUNT(DISTINCT dept_name)
	FROM @uploadInput
	WHERE dept_name IS NOT NULL) > 0
BEGIN
	SELECT 'Please ensure all dept_names are unique then try uploading again.' o
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:update_workbook_deactivate' AS VARBINARY(128))
SET CONTEXT_INFO @ci


BEGIN TRY
BEGIN TRANSACTION

--	merge uploadInput with database table
MERGE BudgetDB.dbo.departments dp
USING @uploadInput ui
ON ui.dept_number=dp.dept_number
WHEN MATCHED THEN
	UPDATE SET dp.dept_name=ui.dept_name,dp.us_0_intl_1=ui.us_0_intl_1
		,dp.active_forecast_option=ui.active_forecast_option
WHEN NOT MATCHED BY TARGET THEN
	INSERT (dept_number, dept_name, active_forecast_option
		,us_0_intl_1)
	VALUES (ui.dept_number, ui.dept_name, ui.active_forecast_option
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
