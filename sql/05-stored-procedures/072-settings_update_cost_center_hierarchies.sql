USE BudgetDB
GO

IF OBJECT_ID('dbo.settings_update_cost_center_hierarchies', 'P') IS NOT NULL
	DROP PROCEDURE dbo.settings_update_cost_center_hierarchies
GO


CREATE PROCEDURE dbo.settings_update_cost_center_hierarchies
	@uploadInput settings_upload_cost_center_hierarchies READONLY
AS
/*
summary:	>
			Uploads changes to be made to
			the dbo.cost_center_hierarchies table 
			and applies them (INSERT or UPDATE)
			as needed.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check whether any BUs/Depts/Teams don't exist in the database
IF (
	SELECT COUNT(*) FROM @uploadInput inpt
	LEFT JOIN BudgetDB.dbo.business_units bu
	ON bu.bu_number=inpt.bu_number
	LEFT JOIN BudgetDB.dbo.departments dp
	ON dp.dept_number=inpt.dept_number
	LEFT JOIN BudgetDB.dbo.teams tm
	ON tm.hfm_team_code=inpt.hfm_team_code
	WHERE bu.bu_number IS NULL
	OR dp.dept_number IS NULL
	OR tm.hfm_team_code IS NULL
) > 0
BEGIN
	SELECT 'Some BUs/Departments/Teams were not found in the database. Please try updating again.' o
	RETURN
END

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:settings_update_cost_center_hierarchies' AS VARBINARY(128))
SET CONTEXT_INFO @ci

BEGIN TRY
BEGIN TRANSACTION
--	merge uploadInput with database table
MERGE BudgetDB.dbo.cost_center_hierarchies cc
USING @uploadInput ui
ON ui.bu_number=cc.bu_number
AND ui.dept_number=cc.dept_number
AND ui.hfm_team_code=cc.hfm_team_code
WHEN MATCHED THEN
	UPDATE SET cc.parent1=ui.parent1,cc.parent2=ui.parent2
		,cc.parent3=ui.parent3,cc.parent4=ui.parent4
WHEN NOT MATCHED BY TARGET THEN
	INSERT (bu_number, dept_number, hfm_team_code
		,parent1, parent2, parent3, parent4)
	VALUES (ui.bu_number, ui.dept_number, ui.hfm_team_code
		,ui.parent1, ui.parent2, ui.parent3, ui.parent4)
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;

SELECT 'Database successfully updated.' o, 5 n
COMMIT TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

END TRY

BEGIN CATCH
--	rollback transaction
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

--	return error message to user
SELECT 'An error occurred in the database while attemping to update the database:' 
	+ CHAR(13)+CHAR(10) + ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
