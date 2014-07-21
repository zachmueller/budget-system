USE BudgetDB
GO

IF OBJECT_ID('dbo.log_changes_workbook_products', 'TR') IS NOT NULL
	DROP TRIGGER dbo.log_changes_workbook_products
GO


CREATE TRIGGER dbo.log_changes_workbook_products
	ON BudgetDB.dbo.workbook_products
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
SELECT @@SPID, @ci, workbook_id, COUNT(*), SYSTEM_USER
	,'workbook_products', GETDATE(), APP_NAME(), action_taken
FROM (
	--	select workbooks either inserted or updated
	SELECT ISNULL(i.workbook_id,d.workbook_id) workbook_id
		,CASE WHEN d.workbook_id IS NULL THEN 'INSERT'
			WHEN d.workbook_id IS NOT NULL THEN 'UPDATE'
			ELSE 'UNKNOWN' END action_taken
	FROM inserted i
	LEFT JOIN deleted d
	ON d.workbook_id=i.workbook_id
	UNION ALL
	--	select workbooks only deleted
	SELECT d.workbook_id, 'DELETE' action_taken
	FROM deleted d
	LEFT JOIN inserted i
	ON i.workbook_id=d.workbook_id
	WHERE i.workbook_id IS NULL
) a
GROUP BY a.action_taken, a.workbook_id

END
GO
