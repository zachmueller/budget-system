USE BudgetDB
GO

IF OBJECT_ID('dbo.log_changes_departments', 'TR') IS NOT NULL
	DROP TRIGGER dbo.log_changes_departments
GO


CREATE TRIGGER dbo.log_changes_departments
	ON BudgetDB.dbo.departments
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
	,records_affected, user_name, record_date, table_name
	,application_name, action_taken)
SELECT @@SPID, @ci, COUNT(*), SYSTEM_USER
	,GETDATE(), 'departments', APP_NAME(), action_taken
FROM (
	--	select items either inserted or updated
	SELECT ISNULL(i.dept_number,d.dept_number) dept_number
		,CASE WHEN d.dept_number IS NULL THEN 'INSERT'
			WHEN d.dept_number IS NOT NULL THEN 'UPDATE'
			ELSE 'UNKNOWN' END action_taken
	FROM inserted i
	LEFT JOIN deleted d
	ON d.dept_number=i.dept_number
	UNION ALL
	--	select items only deleted
	SELECT d.dept_number, 'DELETE' action_taken
	FROM deleted d
	LEFT JOIN inserted i
	ON i.dept_number=d.dept_number
	WHERE i.dept_number IS NULL
) a
GROUP BY a.action_taken

END
GO
