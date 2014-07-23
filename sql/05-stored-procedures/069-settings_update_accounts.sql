USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_update_accounts', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_update_accounts
GO


CREATE PROCEDURE dbo.settings_update_accounts
	@uploadInput settings_upload_accounts READONLY
AS
/*
summary:	>
			Uploads changes to be made to
			the dbo.pl_items table and applies
			them (INSERT or UPDATE) as needed.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check that all names are unique
IF (SELECT MAX(c)-MIN(c)
	FROM (
		SELECT COUNT(*) c
		FROM @uploadInput
		WHERE pl_item IS NOT NULL
		UNION ALL
		SELECT COUNT(*) c
		FROM (
			SELECT DISTINCT pl_item, category_code
			FROM @uploadInput
			WHERE pl_item IS NOT NULL
		) a
	) b
) > 0
BEGIN
	SELECT 'Please ensure all pl_item/category_code combinations are unique then try uploading again.' o
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:settings_update_accounts' AS VARBINARY(128))
SET CONTEXT_INFO @ci


BEGIN TRY
BEGIN TRANSACTION

--	merge uploadInput with database table
MERGE BudgetDB.dbo.pl_items pl
USING @uploadInput ui
ON ui.hfm_account_code=pl.hfm_account_code
WHEN MATCHED THEN
	UPDATE SET pl.pl_item=ui.pl_item, pl.active_forecast_option=ui.active_forecast_option
		,pl.dollar_amount=ui.dollar_amount,pl.rollup_to_hosting_revenue=ui.hosting_revenue
		,pl.category_code=ui.category_code
;

SELECT 'Database successfully updated.' o, 5 n
COMMIT TRANSACTION
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
