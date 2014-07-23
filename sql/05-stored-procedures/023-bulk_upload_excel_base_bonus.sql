USE BudgetDB
GO

IF OBJECT_ID('dbo.bulk_upload_excel_base_bonus', 'P') IS NOT NULL
	DROP PROCEDURE dbo.bulk_upload_excel_base_bonus
GO


CREATE PROCEDURE dbo.bulk_upload_excel_base_bonus
	@uploadInput bulk_upload_base_bonus READONLY
	,@basePLItem NVARCHAR(256)
	,@bonusPLItem NVARCHAR(256)
	,@commissionPLItem NVARCHAR(256)
	,@usIntl BIT			--	whether uploaded from the US or INTL Master Assumptions file
AS
/*
summary:	>
			Used by FP&A analysts to upload new
			assumptions of salary-related data
			that is aggregated as an average of
			the base/bonus/commissions over the
			Company, Location, Business Unit,
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
DECLARE @ci VARBINARY(128) = CAST('sproc:bulk_upload_excel_base_bonus' AS VARBINARY(128))
SET CONTEXT_INFO @ci

BEGIN TRY
BEGIN TRANSACTION
--	collect forecast scenario ID
DECLARE @fcstID INT = (SELECT TOP 1 scenario_id FROM BudgetDB.dbo.scenarios WHERE scenario_name='Forecast')

--	delete old assumptions in base, bonus, and commission calculation tables
DELETE ba FROM BudgetDB.dbo.calculation_table_base ba
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=ba.company_number
WHERE ba.scenario_id=@fcstID AND cp.us_0_intl_1=@usIntl

DELETE bn FROM BudgetDB.dbo.calculation_table_bonus bn
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=bn.company_number
WHERE bn.scenario_id=@fcstID AND cp.us_0_intl_1=@usIntl

DELETE cm FROM BudgetDB.dbo.calculation_table_commission cm
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=cm.company_number
WHERE cm.scenario_id=@fcstID AND cp.us_0_intl_1=@usIntl


--	insert new assumptions into calculation tables
--	base
INSERT INTO BudgetDB.dbo.calculation_table_base (scenario_id, company_number, bu_number, dept_number, hfm_team_code
	,location_number, job_id, ft_pt_count, hfm_account_code, currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9],[Month 10],[Month 11]
	,[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18],[Month 19],[Month 20],[Month 21]
	,[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30],[Month 31]
	,[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @fcstID, ui.company_number, ui.bu_number, ui.dept_number, ui.hfm_team_code, ui.location_number
	,jt.job_id, ui.ft_pt_count, pl.hfm_account_code, cp.currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9],[Month 10],[Month 11]
	,[Month 12],[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18],[Month 19],[Month 20],[Month 21]
	,[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30],[Month 31]
	,[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
FROM @uploadInput ui
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_title=ui.job_title
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=ui.bu_number AND dv.dept_number=ui.dept_number
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.pl_item=@basePLItem AND pl.rollup_to_hosting_revenue IS NULL
	AND pl.category_code=dv.category_code
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_number=ui.company_number
WHERE ui.ft_pt_count>0

--	bonus
INSERT INTO BudgetDB.dbo.calculation_table_bonus (scenario_id, company_number, bu_number, dept_number, hfm_team_code
	,location_number, job_id, ft_pt_count, hfm_account_code, bonus_percent)
SELECT @fcstID, ui.company_number, ui.bu_number, ui.dept_number, ui.hfm_team_code, ui.location_number
	,jt.job_id, ui.ft_pt_count, pl.hfm_account_code, ui.avg_bonus
FROM @uploadInput ui
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_title=ui.job_title
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=ui.bu_number AND dv.dept_number=ui.dept_number
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.pl_item=@bonusPLItem AND pl.rollup_to_hosting_revenue IS NULL
	AND pl.category_code=dv.category_code
WHERE ui.ft_pt_count>0

--	commissions
INSERT INTO BudgetDB.dbo.calculation_table_commission (scenario_id, company_number, bu_number, dept_number, hfm_team_code
	,location_number, job_id, ft_pt_count, hfm_account_code, commission_percent)
SELECT @fcstID, ui.company_number, ui.bu_number, ui.dept_number, ui.hfm_team_code, ui.location_number
	,jt.job_id, ui.ft_pt_count, pl.hfm_account_code, ui.avg_commission
FROM @uploadInput ui
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_title=ui.job_title
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=ui.bu_number AND dv.dept_number=ui.dept_number
LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.pl_item=@commissionPLItem AND pl.rollup_to_hosting_revenue IS NULL
	AND pl.category_code=dv.category_code
WHERE pl.pl_item IS NOT NULL AND ui.ft_pt_count>0


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
SELECT 'An error occurred in the database while attemping to update Base/Bonus/Commission:' 
	+ CHAR(13)+CHAR(10) + ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
