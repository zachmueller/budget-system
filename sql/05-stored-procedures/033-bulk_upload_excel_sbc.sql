USE BudgetDB
GO

IF OBJECT_ID('dbo.bulk_upload_excel_sbc', 'P') IS NOT NULL
	DROP PROCEDURE dbo.bulk_upload_excel_sbc
GO


CREATE PROCEDURE dbo.bulk_upload_excel_sbc
	@uploadInput bulk_upload_sbc READONLY
	,@startDate DATE
	,@sbcPLItem NVARCHAR(256)
AS
/*
summary:	>
			Used by FP&A analysts to upload new
			assumptions of Stock Based Comp data
			that is aggregated as an average over 
			the Company, Location, Business Unit,
			Department, and Team dimensions.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:bulk_upload_excel_sbc' AS VARBINARY(128))
SET CONTEXT_INFO @ci

BEGIN TRY
BEGIN TRANSACTION
--	move upload data into a temp table, joining onto necessary tables
--		for additional data needed
DECLARE @fcstID INT = (SELECT TOP 1 scenario_id FROM BudgetDB.dbo.scenarios
	WHERE scenario_name='Forecast')

SELECT sd.employee_id, ui.participant_id, sd.company_number company_number
	,sd.bu_number bu_number, sd.dept_number dept_number,sd.hfm_team_code hfm_team_code
	,sd.location_number location_number,pl.hfm_account_code, cp.currency_code, ui.[Month 1], ui.[Month 2], ui.[Month 3]
	,ui.[Month 4], ui.[Month 5], ui.[Month 6], ui.[Month 7], ui.[Month 8], ui.[Month 9], ui.[Month 10]
	,ui.[Month 11], ui.[Month 12], ui.[Month 13], ui.[Month 14], ui.[Month 15], ui.[Month 16]
INTO #TempMappedData
FROM @uploadInput ui
LEFT JOIN BudgetDB.dbo.salary_data sd ON sd.employee_id=ui.participant_id
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=sd.bu_number AND dv.dept_number=sd.dept_number
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.pl_item=@sbcPLItem AND pl.category_code=dv.category_code
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=sd.company_number
WHERE sd.employee_id IS NOT NULL	--do not include records where employee ID is missing from GPS data


--	delete old data from sbc calculation table
DELETE FROM BudgetDB.dbo.calculation_table_sbc
WHERE scenario_id = @fcstID

--	create a dynamic query to insert data, grouped, into the calculation table
DECLARE @startDateOffset INT = (SELECT TOP 1 DATEDIFF(m,@startDate,start_date)
		FROM BudgetDB.dbo.scenarios WHERE scenario_id=@fcstID)
	,@loopCounter INT = 0
	,@monthSQL NVARCHAR(MAX) = ''
	,@fullSQL NVARCHAR(MAX) = 'INSERT INTO BudgetDB.dbo.calculation_table_sbc (scenario_id, company_number, bu_number, dept_number
,hfm_team_code, location_number, hfm_account_code, currency_code, [Month 1],[Month 2],[Month 3],[Month 4],[Month 5]
,[Month 6],[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15]
,[Month 16],[Month 17],[Month 18],[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33]
,[Month 34],[Month 35],[Month 36])
SELECT ' + CAST(@fcstID AS NVARCHAR) + ', company_number, bu_number, dept_number, hfm_team_code
,location_number, hfm_account_code, currency_code'

--	loop through 36 months, placing zeros in the query when outside the offset date range
--		or placing the corresponding [Month X] field where necessary
WHILE @loopCounter < 36
BEGIN
	SET @loopCounter = @loopCounter + 1
	SET @startDateOffset = @startDateOffset + 1
	IF @startDateOffset BETWEEN 1 AND 16
	BEGIN
		SET @monthSQL = @monthSQL + ', SUM([Month ' + CAST(@startDateOffset AS NVARCHAR) + '])'
	END
	ELSE
	BEGIN
		SET @monthSQL = @monthSQL + ', 0'
	END
END

SET @fullSQL = @fullSQL + @monthSQL + '
FROM #TempMappedData
WHERE employee_id IS NOT NULL
GROUP BY company_number, bu_number, dept_number, hfm_team_code, location_number, hfm_account_code, currency_code'

--	execute the sql command to insert the grouped data into the calculation table
EXEC sp_executesql @fullSQL

COMMIT TRANSACTION

SELECT 'Successfully updated the database.' o, 1 n

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

END TRY

BEGIN CATCH
--	rollback transaction
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

--	return error message to user
SELECT 'An error occurred in the database while attemping to update:' 
	+ CHAR(13)+CHAR(10) + ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
