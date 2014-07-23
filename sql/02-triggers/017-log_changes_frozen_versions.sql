USE BudgetDB
GO

IF OBJECT_ID('dbo.log_changes_frozen_versions', 'TR') IS NOT NULL
	DROP TRIGGER dbo.log_changes_frozen_versions
GO


CREATE TRIGGER dbo.log_changes_frozen_versions
	ON BudgetDB.dbo.frozen_versions
FOR DELETE, INSERT, UPDATE
AS
/*
summary:	>
			Capture the count of changes made
			to the table, aggregating by whether
			the record was INSERTED, UPDATED, or
			DELETED.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
*/
BEGIN

--	collect CONTEXT_INFO
DECLARE @ci VARCHAR(128) = CONVERT(VARCHAR(128), CONTEXT_INFO())

--	insert data into log
INSERT INTO BudgetDB.dbo.upload_log (spid, attribute
	,workbook_id, records_affected, user_name, table_name
	,record_date, application_name, action_taken)
SELECT @@SPID, @ci, NULL, COUNT(*), SYSTEM_USER
	,'frozen_versions', GETDATE(), APP_NAME(), action_taken
FROM (
	--	select workbooks either inserted or updated
	SELECT ISNULL(i.workbook_id,d.workbook_id) workbook_id
		,CASE WHEN d.id IS NULL THEN 'INSERT'
			WHEN d.id IS NOT NULL THEN 'UPDATE'
			ELSE 'UNKNOWN' END action_taken
	FROM inserted i
	LEFT JOIN deleted d
	ON d.id=i.id
	UNION ALL
	--	select workbooks only deleted
	SELECT d.workbook_id, 'DELETE' action_taken
	FROM deleted d
	LEFT JOIN inserted i
	ON i.id=d.id
	WHERE i.id IS NULL
) a
GROUP BY a.action_taken

END
GO
