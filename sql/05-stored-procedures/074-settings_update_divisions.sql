USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_update_divisions', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_update_divisions
GO


CREATE PROCEDURE dbo.settings_update_divisions
	@uploadInput settings_upload_divisions READONLY
AS
/*
summary:	>
			Uploads changes to be made to
			the dbo.divisions table and applies
			them (INSERT or UPDATE) as needed.
			Allows for DELETEs, as division
			mappings are allowed to be removed
			(i.e., invalidated) unlike the
			raw dimension tables.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:settings_update_divisions' AS VARBINARY(128))
SET CONTEXT_INFO @ci


BEGIN TRY
BEGIN TRANSACTION

--	merge uploadInput with database
MERGE BudgetDB.dbo.divisions dv
USING @uploadInput ui
ON ui.dept_number=dv.dept_number AND ui.bu_number=dv.bu_number
WHEN MATCHED THEN
	UPDATE SET dv.metric=ui.metric, dv.division_name=ui.division_name
		,dv.category_code=ui.category_code
WHEN NOT MATCHED BY TARGET THEN
	INSERT (dept_number, bu_number, division_name, category_code)
	VALUES (ui.dept_number, ui.bu_number, ui.division_name, ui.category_code)
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;


COMMIT TRANSACTION

SELECT 'Successfully updated the database.' o, 1 n

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

END TRY

BEGIN CATCH
--	rollback transaction
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

--	return error message to user
SELECT 'An error occurred in the database while attemping to update:' 
	+ CHAR(13)+CHAR(10) + ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
