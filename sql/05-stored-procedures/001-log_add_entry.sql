USE BudgetDB
GO

IF OBJECT_ID('dbo.log_add_entry', 'P') IS NOT NULL
	DROP PROCEDURE dbo.log_add_entry
GO


CREATE PROCEDURE dbo.log_add_entry
	@action NVARCHAR(100) = NULL		--	defines what action the user or procedure took
	,@tableName NVARCHAR(128) = NULL
	,@wbID INT = NULL					--	workbook ID, if applicable
	,@rowCount INT = NULL
	,@attr NVARCHAR(256) = NULL			--	any attribute/extra info for the log
	,@errorMsg NVARCHAR(1024) = NULL	--	error message, if applicable
AS
/*
summary:	>
			Adds individual entry to the log table. Primarily used
			for debugging during development or logging user actions
			such as refreshing data pulls in the workbooks.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-15
*/
SET NOCOUNT ON

--	collect CONTEXT_INFO
DECLARE @ci VARCHAR(128) = CONVERT(VARCHAR(128), CONTEXT_INFO())

--	add to log
INSERT INTO BudgetDB.dbo.upload_log (action_taken, table_name
	,workbook_id, records_affected, attribute, user_name
	,record_date, application_name, spid)
VALUES (@action, @tableName, @wbID, @rowCount
	,LEFT(@ci + ';' + ISNULL(@attr,''), 256)
	,SYSTEM_USER, GETDATE(), APP_NAME(), @@SPID)

GO
