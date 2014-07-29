USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_update_categories', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_update_categories
GO


CREATE PROCEDURE dbo.settings_update_categories
	@categoryID INT
	,@categoryName NVARCHAR(256)
AS
/*
summary:	>
			Updates a category value from the
			dbo.categories table.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-28
*/

SET NOCOUNT ON

--	check that category exists
IF (SELECT COUNT(*) FROM BudgetDB.dbo.categories
	WHERE category_id=@categoryID) = 0
BEGIN
	SELECT 'Category ID ' + CAST(@categoryID AS NVARCHAR) + ' does not exist in the database.' o
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:settings_update_categories' AS VARBINARY(128))
SET CONTEXT_INFO @ci

BEGIN TRY
BEGIN TRANSACTION

--	update category
UPDATE BudgetDB.dbo.categories
SET category_name=@categoryName
WHERE category_id=@categoryID

COMMIT TRANSACTION

SELECT 'Successfully updated the category.' msg

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

END TRY

BEGIN CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

SELECT 'An error occurred in the database when trying to update the category:'
	+ CHAR(13)+CHAR(10) + ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
