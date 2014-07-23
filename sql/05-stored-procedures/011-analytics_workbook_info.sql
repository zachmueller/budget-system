USE BudgetDB
GO

IF OBJECT_ID('dbo.analytics_workbook_info', 'P') IS NOT NULL
	DROP PROCEDURE dbo.analytics_workbook_info
GO


CREATE PROCEDURE dbo.analytics_workbook_info
AS
/*
summary:	>
			Simple procedure to download basic data
			about the forecasting and rollup workbooks.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-15
*/
SET NOCOUNT ON

--	select out details on all workbooks, in human-readable form
SELECT wb.workbook_id, wb.workbook_name
	,CASE WHEN output_only=1 THEN 'Rollup'
		ELSE 'Forecast Template' END workbook_type
	,CASE WHEN us_0_intl_1 IS NULL THEN 'Both'
		WHEN us_0_intl_1=0 THEN 'US'
		ELSE 'INTL' END us_or_intl
	,CASE WHEN active_workbook=1 THEN 'Active'
		ELSE 'Inactive' END active_workbook
	,CAST(lf.last_updated_date AS DATETIME) last_updated_date
	,lf.last_updated_by, lfc.forecast_record_count
FROM BudgetDB.dbo.workbooks wb
LEFT JOIN (	--	grab most recent record updated in live forecast for each workbook
	SELECT workbook_id, last_updated_date
		,last_updated_by, ROW_NUMBER() OVER (PARTITION BY workbook_id 
			ORDER BY last_updated_date DESC) RN
	FROM BudgetDB.dbo.live_forecast
) lf ON lf.workbook_id=wb.workbook_id
AND lf.RN=1
LEFT JOIN (	--	grab total number of records currently in the live forecast
	SELECT workbook_id, COUNT(*) forecast_record_count
	FROM BudgetDB.dbo.live_forecast
	GROUP BY workbook_id
) lfc ON lfc.workbook_id=wb.workbook_id

GO
