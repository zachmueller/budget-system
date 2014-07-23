USE BudgetDB
GO

IF OBJECT_ID('dbo.analytics_upload_log', 'P') IS NOT NULL
	DROP PROCEDURE dbo.analytics_upload_log
GO


CREATE PROCEDURE dbo.analytics_upload_log
	@d DATE = NULL	--	simple date input to filter by
AS
/*
summary:	>
			Simple procedure to allow analysts
			to view the log detail.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-15
*/
SET NOCOUNT ON

--	set datetime variable for filtering
DECLARE @t DATETIME2 = ISNULL(
	--	get last millisecond of input date (more
	--	intuitive to the user)
	DATEADD(ms,-1,DATEADD(d,1,CAST(@d AS DATETIME2)))
	,GETDATE())

--	select out log data
SELECT TOP 5000 *
FROM BudgetDB.dbo.upload_log
WHERE record_date <= @t
ORDER BY record_date DESC

GO
