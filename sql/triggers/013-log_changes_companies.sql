USE BudgetDB
GO

IF OBJECT_ID('dbo.log_changes_companies', 'TR') IS NOT NULL
	DROP TRIGGER dbo.log_changes_companies
GO


CREATE TRIGGER dbo.log_changes_companies
	ON BudgetDB.dbo.companies
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
	,GETDATE(), 'companies', APP_NAME(), action_taken
FROM (
	--	select items either inserted or updated
	SELECT ISNULL(i.company_number,d.company_number) company_number
		,CASE WHEN d.company_number IS NULL THEN 'INSERT'
			WHEN d.company_number IS NOT NULL THEN 'UPDATE'
			ELSE 'UNKNOWN' END action_taken
	FROM inserted i
	LEFT JOIN deleted d
	ON d.company_number=i.company_number
	UNION ALL
	--	select items only deleted
	SELECT d.company_number, 'DELETE' action_taken
	FROM deleted d
	LEFT JOIN inserted i
	ON i.company_number=d.company_number
	WHERE i.company_number IS NULL
) a
GROUP BY a.action_taken

END
GO
