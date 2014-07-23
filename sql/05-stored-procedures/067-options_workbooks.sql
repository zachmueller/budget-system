USE BudgetDB
GO

IF OBJECT_ID('dbo.options_workbooks', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_workbooks
GO


CREATE PROCEDURE dbo.options_workbooks
	@wbID INT = 0
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of workbook names and their IDs,
			filtered to only an individual
			workbook ID, if one is provided.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

IF ( @wbID=0 )
BEGIN	--	if default input provided, list all workbooks
	SELECT wb.workbook_name, wb.workbook_id
	FROM BudgetDB.dbo.workbooks wb
END

ELSE

BEGIN
	IF ( @wbID IS NULL )
	BEGIN	--	if NULL provided, list NULL values
		SELECT NULL workbook_name
			,NULL workbook_id
	END

	ELSE

	BEGIN	--	otherwise, list details for provided workbook ID
		SELECT wb.workbook_name, wb.workbook_id
		FROM BudgetDB.dbo.workbooks wb
		WHERE wb.workbook_id=@wbID
	END
END

GO
