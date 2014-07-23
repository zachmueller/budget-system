USE BudgetDB
GO

IF OBJECT_ID('dbo.update_workbook_scenarios', 'P') IS NOT NULL
	DROP PROCEDURE dbo.update_workbook_scenarios
GO


CREATE PROCEDURE dbo.update_workbook_scenarios
	@wbID INT
	,@scenario1 INT = NULL
	,@scenario2 INT = NULL
	,@scenario3 INT = NULL
	,@scenario4 INT = NULL
	,@scenario5 INT = NULL
AS
/*
summary:	>
			Updates the list of scenarios selected
			for a workbook, DELETEing and INSERTing
			records as needed.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check that workbook exists
IF (SELECT COUNT(*) FROM BudgetDB.dbo.workbooks
	WHERE workbook_id=@wbID) = 0
BEGIN
	SELECT 'Workbook ID not found in the database' o
	RETURN
END

--	create temp table to hold IDs
CREATE TABLE #TempScenarios (
	scenario_id INT
)

--	insert scenario IDs into temp table
INSERT INTO #TempScenarios (scenario_id)
SELECT sn FROM (
	SELECT @scenario1 sn UNION
	SELECT @scenario2 sn UNION
	SELECT @scenario3 sn UNION
	SELECT @scenario4 sn UNION
	SELECT @scenario5 sn
) a WHERE sn IS NOT NULL

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:update_workbook_scenarios' AS VARBINARY(128))
SET CONTEXT_INFO @ci

BEGIN TRY
BEGIN TRANSACTION

--	merge with permanent table
MERGE BudgetDB.dbo.workbook_scenarios wb
USING #TempScenarios t
ON t.scenario_id=wb.scenario_id
AND wb.workbook_id=@wbID
WHEN NOT MATCHED BY SOURCE AND wb.workbook_id=@wbID THEN
	DELETE
WHEN NOT MATCHED BY TARGET THEN
	INSERT (workbook_id, scenario_id)
	VALUES (@wbID, t.scenario_id);

COMMIT TRANSACTION

SELECT 'Successfully updated this workbook''s scenarios.' msg, COUNT(*) sn_count
FROM BudgetDB.dbo.workbook_scenarios
WHERE workbook_id=@wbID

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

END TRY

BEGIN CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

SELECT 'An error occurred in the database when trying to update the workbook scenario selection:'
	+ CHAR(13)+CHAR(10) + ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
