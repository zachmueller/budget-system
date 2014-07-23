USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_update_products', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_update_products
GO


CREATE PROCEDURE dbo.settings_update_products
	@uploadInput settings_upload_products READONLY
AS
/*
summary:	>
			Uploads changes to be made to
			the dbo.products table and applies
			them (INSERT or UPDATE) as needed.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check that all names are unique
IF (SELECT COUNT(*)-COUNT(DISTINCT product_name)
	FROM @uploadInput
	WHERE product_name IS NOT NULL) > 0
BEGIN
	SELECT 'Please ensure all product_names are unique then try uploading again.' o
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:settings_update_products' AS VARBINARY(128))
SET CONTEXT_INFO @ci


BEGIN TRY
BEGIN TRANSACTION

--	merge uploadInput with database table
MERGE BudgetDB.dbo.products pd
USING @uploadInput ui
ON ui.hfm_product_code=pd.hfm_product_code
WHEN MATCHED THEN
	UPDATE SET pd.product_name=ui.product_name,pd.us_0_intl_1=ui.us_0_intl_1
		,pd.product_consolidation=ui.product_consolidation
		,pd.active_forecast_option=ui.active_forecast_option
WHEN NOT MATCHED BY TARGET THEN
	INSERT (hfm_product_code, product_name, product_consolidation
		,active_forecast_option, us_0_intl_1)
	VALUES (ui.hfm_product_code, ui.product_name, ui.product_consolidation
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
