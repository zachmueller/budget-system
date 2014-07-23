USE BudgetDB
GO

IF OBJECT_ID('dbo.bulk_upload_excel_salaries', 'P') IS NOT NULL
	DROP PROCEDURE dbo.bulk_upload_excel_salaries
GO


CREATE PROCEDURE dbo.bulk_upload_excel_salaries
	@uploadInput bulk_upload_salaries READONLY
	,@usIntl BIT = 0
AS
/*
summary:	>
			Used by FP&A analysts to upload the lastest
			headcount report from the HR system with
			salary and dimension-mapping data
			for each individual employee.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:bulk_upload_excel_salaries' AS VARBINARY(128))
SET CONTEXT_INFO @ci

BEGIN TRY
BEGIN TRANSACTION

--	create temp table with unique job titles
SELECT DISTINCT job_title
INTO #TempJobTitles
FROM @uploadInput

--	merge temp table with job titles table to insert any new titles
MERGE BudgetDB.dbo.job_titles jt
USING #TempJobTitles tjt
ON tjt.job_title=jt.job_title
WHEN NOT MATCHED BY TARGET THEN
	INSERT (job_title)
	VALUES (tjt.job_title)
;

--	drop temp tables
DROP TABLE #TempJobTitles


--	create temp table to pull in job_id
SELECT ui.employee_id, ui.last_name, ui.first_name, ui.job_code, jt.job_id
	,ui.manager, ui.ft_pt, ui.base, ui.bonus, ui.commission_target
	,ui.company_number, ui.location_number
	,ui.bu_number, ui.dept_number, ui.hfm_team_code
INTO #TempUpload
FROM @uploadInput ui
LEFT JOIN BudgetDB.dbo.job_titles jt
ON jt.job_title=ui.job_title

--	delete old data in salaries table
DELETE sd
FROM BudgetDB.dbo.salary_data sd
JOIN BudgetDB.dbo.companies cp
ON cp.company_number=sd.company_number
AND cp.us_0_intl_1=@usIntl

--	insert temp table data into salaries table
INSERT INTO BudgetDB.dbo.salary_data (employee_id, last_name, first_name, job_code
	,job_id, manager, ft_pt, base, bonus, commission_target, company_number
	,location_number, bu_number, dept_number, hfm_team_code)
SELECT employee_id, last_name, first_name, job_code, job_id, manager, ft_pt, base, bonus
	,commission_target, company_number, location_number,bu_number, dept_number, hfm_team_code
FROM #TempUpload

--	drop temp table
DROP TABLE #TempUpload

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
