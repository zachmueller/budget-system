USE BudgetDB
GO

IF OBJECT_ID('dbo.excel_get_backup_workbook_options', 'P') IS NOT NULL
	DROP PROCEDURE dbo.excel_get_backup_workbook_options
GO


CREATE PROCEDURE dbo.excel_get_backup_workbook_options
	@wbID INT
AS
/*
summary:	>
			Used to download a workbook's
			defined dimensions during the
			create from backup process to
			have them listed out on the Create
			sheet of the template prior to
			recreating the workbook from
			the backed-up data.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

SELECT 'Companies' item, ISNULL(cp.company_name,'INCLUDE ALL') item_name
FROM BudgetDB.dbo.workbook_companies wbcp
LEFT JOIN BudgetDB.dbo.companies cp
ON cp.company_number=wbcp.company_number
WHERE wbcp.workbook_id=@wbID
UNION
SELECT 'Business Units' item, ISNULL(bu.bu_name,'INCLUDE ALL') item_name
FROM BudgetDB.dbo.workbook_business_units wbbu
LEFT JOIN BudgetDB.dbo.business_units bu
ON bu.bu_number=wbbu.bu_number
WHERE wbbu.workbook_id=@wbID
UNION
SELECT 'Departments' item, ISNULL(dp.dept_name,'INCLUDE ALL') item_name
FROM BudgetDB.dbo.workbook_departments wbdp
LEFT JOIN BudgetDB.dbo.departments dp
ON dp.dept_number=wbdp.dept_number
WHERE wbdp.workbook_id=@wbID
UNION
SELECT DISTINCT 'Teams' item, ISNULL(tm.team_consolidation,'INCLUDE ALL') item_name
FROM BudgetDB.dbo.workbook_teams wbtm LEFT JOIN BudgetDB.dbo.teams tm
ON tm.hfm_team_code=wbtm.hfm_team_code
WHERE wbtm.workbook_id=@wbID
UNION
SELECT 'Locations' item, ISNULL(lc.location_name,'INCLUDE ALL') item_name
FROM BudgetDB.dbo.workbook_locations wblc
LEFT JOIN BudgetDB.dbo.locations lc
ON lc.location_number=wblc.location_number
WHERE wblc.workbook_id=@wbID
UNION
SELECT 'Products' item, ISNULL(pd.product_name,'INCLUDE ALL') item_name
FROM BudgetDB.dbo.workbook_products wbpd
LEFT JOIN BudgetDB.dbo.products pd
ON pd.hfm_product_code=wbpd.hfm_product_code
WHERE wbpd.workbook_id=@wbID
ORDER BY item ASC

GO
