USE BudgetDB
GO

IF OBJECT_ID('dbo.log_changes_calculation_table_bonus_payout_pct', 'TR') IS NOT NULL
	DROP TRIGGER dbo.log_changes_calculation_table_bonus_payout_pct
GO


CREATE TRIGGER dbo.log_changes_calculation_table_bonus_payout_pct
	ON BudgetDB.dbo.calculation_table_bonus_payout_pct
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
	,GETDATE(), 'calculation_table_bonus_payout_pct', APP_NAME(), action_taken
FROM (
	--	select items either inserted or updated
	SELECT CASE WHEN d.scenario_id IS NULL THEN 'INSERT'
			WHEN d.scenario_id IS NOT NULL THEN 'UPDATE'
			ELSE 'UNKNOWN' END action_taken
	FROM inserted i
	LEFT JOIN deleted d
	ON d.scenario_id=i.scenario_id
	UNION ALL
	--	select items only deleted
	SELECT 'DELETE' action_taken
	FROM deleted d
	LEFT JOIN inserted i
	ON d.scenario_id=i.scenario_id
	WHERE i.scenario_id IS NULL
) a
GROUP BY a.action_taken

END
GO
