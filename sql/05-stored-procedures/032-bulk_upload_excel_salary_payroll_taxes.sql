USE BudgetDB
GO

IF OBJECT_ID('dbo.bulk_upload_excel_salary_payroll_taxes', 'P') IS NOT NULL
	DROP PROCEDURE dbo.bulk_upload_excel_salary_payroll_taxes
GO


CREATE PROCEDURE dbo.bulk_upload_excel_salary_payroll_taxes
	@uploadInput bulk_upload_salary_payroll_taxes READONLY
	,@ptPLItem NVARCHAR(256)
	,@usIntl BIT
AS
/*
summary:	>
			Used by FP&A analysts to upload new
			assumptions of payroll tax rates
			to be applied to direct salary-related
			expenses, e.g., Base, Bonus, etc.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:bulk_upload_excel_salary_payroll_taxes' AS VARBINARY(128))
SET CONTEXT_INFO @ci

BEGIN TRY
BEGIN TRANSACTION
--	collect forecast scenario ID
DECLARE @fcstID INT = (SELECT TOP 1 scenario_id FROM BudgetDB.dbo.scenarios WHERE scenario_name='Forecast')

--	delete old payroll tax assumptions
DELETE spt FROM BudgetDB.dbo.calculation_table_salary_payroll_taxes spt
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=spt.company_number
WHERE spt.scenario_id=@fcstID AND cp.us_0_intl_1=@usIntl

--	insert new assumptions
INSERT INTO BudgetDB.dbo.calculation_table_salary_payroll_taxes (scenario_id, bu_number, company_number, hfm_account_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9],[Month 10],[Month 11]
	,[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18],[Month 19],[Month 20],[Month 21]
	,[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30],[Month 31]
	,[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @fcstID, bu.bu_number, cp.company_number, pl.hfm_account_code, [Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6]
	,[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16]
	,[Month 17],[Month 18],[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25],[Month 26]
	,[Month 27],[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM @uploadInput ui
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.pl_item=@ptPLItem AND pl.rollup_to_hosting_revenue IS NULL
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_name=ui.company_name
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_name=ui.bu_name

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
SELECT 'An error occurred in the database while attemping to update Salary Payroll Taxes:' 
	+ CHAR(13)+CHAR(10) + ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
