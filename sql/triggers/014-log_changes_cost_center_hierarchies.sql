USE BudgetDB
GO

IF OBJECT_ID('dbo.log_changes_cost_center_hierarchies', 'TR') IS NOT NULL
	DROP TRIGGER dbo.log_changes_cost_center_hierarchies
GO


CREATE TRIGGER dbo.log_changes_cost_center_hierarchies
	ON BudgetDB.dbo.cost_center_hierarchies
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
	,GETDATE(), 'cost_center_hierarchies', APP_NAME(), action_taken
FROM (
	--	select items either inserted or updated
	SELECT ISNULL(i.bu_number,d.bu_number) bu_number
		,CASE WHEN d.bu_number IS NULL THEN 'INSERT'
			WHEN d.bu_number IS NOT NULL THEN 'UPDATE'
			ELSE 'UNKNOWN' END action_taken
	FROM inserted i
	LEFT JOIN deleted d
	ON d.bu_number=i.bu_number
	AND d.dept_number=i.dept_number
	AND d.hfm_team_code=i.hfm_team_code
	UNION ALL
	--	select items only deleted
	SELECT d.bu_number, 'DELETE' action_taken
	FROM deleted d
	LEFT JOIN inserted i
	ON i.bu_number=d.bu_number
	AND i.dept_number=d.dept_number
	AND i.hfm_team_code=d.hfm_team_code
	WHERE i.bu_number IS NULL
) a
GROUP BY a.action_taken

END
GO
