USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_add_categories', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_add_categories
GO


CREATE PROCEDURE dbo.settings_add_categories
	@categoryName NVARCHAR(256)
AS
/*
summary:	>
			Adds a new category value to the
			dbo.categories table.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-28
*/

SET NOCOUNT ON

--	check that category does not already exist
IF (SELECT COUNT(*) FROM BudgetDB.dbo.categories
	WHERE category_name=@categoryName) > 0
BEGIN
	SELECT 'Category ''' + @categoryName + ''' already exists in the database.' o
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:settings_add_categories' AS VARBINARY(128))
SET CONTEXT_INFO @ci

BEGIN TRY
BEGIN TRANSACTION

--	add new category
INSERT INTO BudgetDB.dbo.categories (category_name)
VALUES (@categoryName)

COMMIT TRANSACTION

SELECT 'Successfully added the category.' msg

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

END TRY

BEGIN CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

SELECT 'An error occurred in the database when trying to add the category:'
	+ CHAR(13)+CHAR(10) + ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
