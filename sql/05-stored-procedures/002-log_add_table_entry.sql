USE BudgetDB
GO

IF OBJECT_ID('dbo.log_add_table_entry', 'P') IS NOT NULL
	DROP PROCEDURE dbo.log_add_table_entry
GO


CREATE PROCEDURE dbo.log_add_table_entry
	@tbl log_table_type READONLY		--	special table type for this procedure
	,@tableName NVARCHAR(128) = NULL
	,@wbID INT = NULL
	,@attr NVARCHAR(256) = NULL			--	any attribute/extra info for the log
	,@errorMsg NVARCHAR(1024) = NULL	--	error message, if applicable
AS
/*
summary:	>
			Adds entries to the log table, based on data in the @tbl
			variable and grouped by its action_taken field. Initially
			used to log changes made as a result of MERGE statements,
			collecting all changes via its OUTPUT.
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
INSERT INTO BudgetDB.dbo.upload_log (action_taken
	,table_name, workbook_id, records_affected
	,attribute, user_name, record_date
	,application_name, spid)
SELECT action_taken, @tableName, @wbID, COUNT(*)
	,LEFT(@ci + ';' + ISNULL(@attr,''), 256)
	,SYSTEM_USER, GETDATE(), APP_NAME(), @@SPID
FROM @tbl
--	aggregate by type of change made
GROUP BY action_taken

GO
