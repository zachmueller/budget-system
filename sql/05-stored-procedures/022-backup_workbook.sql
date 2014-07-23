USE BudgetDB
GO

IF OBJECT_ID('dbo.backup_workbook', 'P') IS NOT NULL
	DROP PROCEDURE dbo.backup_workbook
GO


CREATE PROCEDURE dbo.backup_workbook
	@wbID INT				--	workbook ID
	,@fileVersion NVARCHAR(256)
	,@bData bulk_upload_backup_cells READONLY
	,@expRows INT = 0		--	# of Rows that have been added on the Expenses tab
	,@revRows INT = 0		--	# of Rows that have been added on the Revenue tab
	,@hcRows INT = 0		--	# of Rows that have been added on the Headcount tab
AS
/*
summary:	>
			Upload from the Excel workbooks all
			user-editable cell values in the workbook
			to create snapshots from which the workbooks
			can be recreated, generally used for
			rolling out new versions of the template.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

--	check that workbook exists
IF (SELECT COUNT(*) FROM BudgetDB.dbo.workbooks
	WHERE workbook_id=@wbID) = 0
BEGIN
	SELECT 'Workbook ID not found in the database' o
	RETURN
END

BEGIN TRY
--	add workbook ID to temp table
SELECT @wbID AS workbook_id, @fileVersion AS file_version
INTO #TempWBID

--	create temp table for backup_id
CREATE TABLE #TempBackupID (
	backup_id INT
)


BEGIN TRANSACTION
--	Insert new record into backups table, get new backup_id
MERGE BudgetDB.dbo.backups bk
USING #TempWBID t
ON 1=0
WHEN NOT MATCHED THEN
	INSERT(workbook_id, file_version, backup_date
		,expenses_rows_added, revenue_rows_added, headcount_rows_added)
	VALUES (t.workbook_id, t.file_version, GETDATE(), @expRows, @revRows, @hcRows)
OUTPUT inserted.backup_id INTO #TempBackupID;

--	store backup_id in variable
DECLARE @bID INT = (SELECT TOP 1 backup_id FROM #TempBackupID)
DROP TABLE #TempBackupID
DROP TABLE #TempWBID

--	insert data from upload into backup_formulas table using new backup_id
INSERT INTO BudgetDB.dbo.backup_formulas
	(backup_id, sheet_name, excel_row, excel_column, formula_text)
SELECT @bID, sheet_name, excel_row, excel_column, formula_text
FROM @bData

COMMIT TRANSACTION

--	return with success message
SELECT 'Successfully created a backup of the current workbook in the database.' o, 0 n
END TRY

BEGIN CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
IF OBJECT_ID('tempdb..#TempWBID') IS NOT NULL DROP TABLE #TempWBID
IF OBJECT_ID('tempdb..#TempBackupID') IS NOT NULL DROP TABLE #TempBackupID
SELECT 'Failure to create backup in the database:' + CHAR(13)+CHAR(10) + ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
