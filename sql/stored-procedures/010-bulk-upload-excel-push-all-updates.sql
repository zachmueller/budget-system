USE BudgetDB
GO


IF OBJECT_ID('dbo.bulk_upload_excel_push_all_updates', 'P') IS NOT NULL
	DROP PROCEDURE dbo.bulk_upload_excel_push_all_updates
GO


CREATE PROCEDURE dbo.bulk_upload_excel_push_all_updates
	@tbl bulk_upload_push_all READONLY
	,@wbID INT
AS
/*

*/

--	suppress counts and warnings from interfering with upload
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

--	check that workbook_id exists and is active
IF (SELECT COUNT(*)
	FROM BudgetDB.dbo.workbooks
	WHERE workbook_id=@wbID
	AND active_workbook=1
	) = 0
BEGIN
	--	query out response to user
	SELECT 'Error on upload: Workbook does not exist or is set to Inactive.'
		+ CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10) + 'Workbook ID provided: '
		+ CAST(@wbID AS NVARCHAR) o
	RETURN
END


--	validate upload prior to attempting updates
CREATE TABLE #TempErrors (
	dimension NVARCHAR(256)
	,item_name NVARCHAR(256)
	,error_type NVARCHAR(256)
)

INSERT INTO #TempErrors (dimension, item_name, error_type)
SELECT dim, item, er
FROM (
	SELECT 'Company' dim, t.company_name item, 'Invalid' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_name=t.company_name
	WHERE cp.company_number IS NULL 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Company' dim, t.company_name item, 'Inactive' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_name=t.company_name
	WHERE cp.active_forecast_option=0 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Company' dim, t.company_name item, 'Not selected in workbook' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_name=t.company_name
	LEFT JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=@wbID
	AND ISNULL(wbcp.company_number,cp.company_number)=cp.company_number
	WHERE cp.active_forecast_option=1 AND ISNULL(wbcp.company_number,cp.company_number) IS NULL
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'BU' dim, t.bu_name item, 'Invalid' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_name=t.bu_name
	WHERE bu.bu_number IS NULL 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'BU' dim, t.bu_name item, 'Inactive' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_name=t.bu_name
	WHERE bu.active_forecast_option=0 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'BU' dim, t.bu_name item, 'Not selected in workbook' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_name=t.bu_name
	LEFT JOIN BudgetDB.dbo.workbook_business_units wbbu ON wbbu.workbook_id=@wbID
	AND ISNULL(wbbu.bu_number,bu.bu_number)=bu.bu_number
	WHERE bu.active_forecast_option=1 AND ISNULL(wbbu.bu_number,bu.bu_number) IS NULL
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Department' dim, t.dept_name item, 'Invalid' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_name=t.dept_name
	WHERE dp.dept_number IS NULL 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Department' dim, t.dept_name item, 'Inactive' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_name=t.dept_name
	WHERE dp.active_forecast_option=0 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Department' dim, t.dept_name item, 'Not selected in workbook' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_name=t.dept_name
	LEFT JOIN BudgetDB.dbo.workbook_departments wbdp ON wbdp.workbook_id=@wbID
	AND ISNULL(wbdp.dept_number,dp.dept_number)=dp.dept_number
	WHERE dp.active_forecast_option=1 AND ISNULL(wbdp.dept_number,dp.dept_number) IS NULL
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Division' dim, t.bu_name + '---' + t.dept_name item, 'Invalid' er
	FROM @tbl t
	JOIN BudgetDB.dbo.departments dp ON dp.dept_name=t.dept_name
	JOIN BudgetDB.dbo.business_units bu ON bu.bu_name=t.bu_name
	LEFT JOIN BudgetDB.dbo.divisions dv ON dv.dept_number=dp.dept_number
		AND dv.bu_number=bu.bu_number
	WHERE dv.dept_number IS NULL 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Job Title' dim, t.job_title item, 'Invalid' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_title=t.job_title
	WHERE jt.job_id IS NULL 
	AND t.record_type IN ('Headcount')
	UNION
	SELECT 'Team' dim, t.team_name item, 'Invalid' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.team_name=t.team_name
	WHERE tm.hfm_team_code IS NULL 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Team' dim, t.team_name item, 'Inactive' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.team_name=t.team_name
	WHERE tm.active_forecast_option=0 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Team' dim, t.team_name item, 'Not selected in workbook' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.teams tm ON tm.team_name=t.team_name
	LEFT JOIN BudgetDB.dbo.workbook_teams wbtm ON wbtm.workbook_id=@wbID
	AND ISNULL(wbtm.hfm_team_code,tm.hfm_team_code)=tm.hfm_team_code
	WHERE tm.active_forecast_option=1 AND ISNULL(wbtm.hfm_team_code,tm.hfm_team_code) IS NULL
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Location' dim, t.location_name item, 'Invalid' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_name=t.location_name
	WHERE lc.location_number IS NULL 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Location' dim, t.location_name item, 'Inactive' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_name=t.location_name
	WHERE lc.active_forecast_option=0 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Location' dim, t.location_name item, 'Not selected in workbook' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_name=t.location_name
	LEFT JOIN BudgetDB.dbo.workbook_locations wblc ON wblc.workbook_id=@wbID
	AND ISNULL(wblc.location_number,lc.location_number)=lc.location_number
	WHERE lc.active_forecast_option=1 AND ISNULL(wblc.location_number,lc.location_number) IS NULL
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Product' dim, t.product_name item, 'Invalid' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.products pd ON pd.product_name=t.product_name
	WHERE pd.hfm_product_code IS NULL 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Product' dim, t.product_name item, 'Inactive' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.products pd ON pd.product_name=t.product_name
	WHERE pd.active_forecast_option=0 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Product' dim, t.product_name item, 'Not selected in workbook' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.products pd ON pd.product_name=t.product_name
	LEFT JOIN BudgetDB.dbo.workbook_products wbpd ON wbpd.workbook_id=@wbID
	AND ISNULL(wbpd.hfm_product_code,pd.hfm_product_code)=pd.hfm_product_code
	WHERE pd.active_forecast_option=1 AND ISNULL(wbpd.hfm_product_code,pd.hfm_product_code) IS NULL
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'P&L Item' dim, t.pl_item item, 'Invalid' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.pl_item=t.pl_item
	WHERE pl.hfm_account_code IS NULL 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'P&L Item' dim, t.pl_item item, 'Inactive' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.pl_items pl ON pl.pl_item=t.pl_item
	WHERE pl.active_forecast_option=0 
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Category' dim, t.category item, 'Invalid' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.categories ct ON ct.category_name=t.category
	WHERE ct.category_id IS NULL  AND t.category IS NOT NULL
	AND t.record_type IN ('Headcount','Revenue','Expenses')
	UNION
	SELECT 'Currency' dim, t.currency_code item, 'Invalid' er
	FROM @tbl t
	LEFT JOIN BudgetDB.dbo.currencies cr ON cr.currency_code=t.currency_code
	WHERE cr.currency_code IS NULL AND t.currency_code IS NOT NULL
) a

IF (SELECT COUNT(*) FROM #TempErrors) > 0 
BEGIN
	SELECT TOP 20 er
	FROM (
		SELECT 1 ob, 'Errors exist in the upload data:' + CHAR(13)+CHAR(10) er
		UNION ALL
		SELECT 2 ob, dimension + ': ' + item_name + ' (' + error_type + ')' er
		FROM #TempErrors
	) a
	ORDER BY ob ASC
	IF OBJECT_ID('tempdb..#TempErrors') IS NOT NULL DROP TABLE #TempErrors
	RETURN
END

IF OBJECT_ID('tempdb..#TempErrors') IS NOT NULL DROP TABLE #TempErrors


--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:bulk_upload_excel_push_all_updates' AS VARBINARY(128))
SET CONTEXT_INFO @ci

--	create table for output
CREATE TABLE #TempOut (
	action_taken NVARCHAR(30)
	,sheet_name NVARCHAR(50)
	,excel_row INT
	,id INT
)


--	break input into parts and push updates to database
BEGIN TRY
BEGIN TRANSACTION
--	collect Forecast scenario ID
DECLARE @fcstID INT = (SELECT TOP 1 scenario_id
	FROM BudgetDB.dbo.scenarios
	WHERE scenario_name='Forecast')

---------------------------------
--	Headcount/Revenue/Expenses
--	parse out relevant data
CREATE TABLE #TempMain (
	workbook_id INT, sheet_name NVARCHAR(50), excel_row INT, job_id INT
	,currency_code NCHAR(3),scenario_id INT, company_number NCHAR(3), bu_number NVARCHAR(100)
	,dept_number NCHAR(4), hfm_team_code NVARCHAR(100), hfm_product_code NVARCHAR(100)
	,location_number NCHAR(3), hfm_account_code NVARCHAR(100), category_id INT
	,[description] NVARCHAR(256), forecast_method NVARCHAR(256), forecast_rate DECIMAL(30,16)
	,[Month 1] DECIMAL(30,16),[Month 2] DECIMAL(30,16),[Month 3] DECIMAL(30,16)
	,[Month 4] DECIMAL(30,16),[Month 5] DECIMAL(30,16),[Month 6] DECIMAL(30,16)
	,[Month 7] DECIMAL(30,16),[Month 8] DECIMAL(30,16),[Month 9] DECIMAL(30,16)
	,[Month 10] DECIMAL(30,16),[Month 11] DECIMAL(30,16),[Month 12] DECIMAL(30,16)
	,[Month 13] DECIMAL(30,16),[Month 14] DECIMAL(30,16),[Month 15] DECIMAL(30,16)
	,[Month 16] DECIMAL(30,16),[Month 17] DECIMAL(30,16),[Month 18] DECIMAL(30,16)
	,[Month 19] DECIMAL(30,16),[Month 20] DECIMAL(30,16),[Month 21] DECIMAL(30,16)
	,[Month 22] DECIMAL(30,16),[Month 23] DECIMAL(30,16),[Month 24] DECIMAL(30,16)
	,[Month 25] DECIMAL(30,16),[Month 26] DECIMAL(30,16),[Month 27] DECIMAL(30,16)
	,[Month 28] DECIMAL(30,16),[Month 29] DECIMAL(30,16),[Month 30] DECIMAL(30,16)
	,[Month 31] DECIMAL(30,16),[Month 32] DECIMAL(30,16),[Month 33] DECIMAL(30,16)
	,[Month 34] DECIMAL(30,16),[Month 35] DECIMAL(30,16),[Month 36] DECIMAL(30,16)
)

INSERT INTO #TempMain (scenario_id, workbook_id, company_number, bu_number, job_id
	,dept_number, hfm_team_code, location_number, hfm_product_code, hfm_account_code
	,category_id,[description],sheet_name,excel_row,forecast_method,forecast_rate,currency_code
	,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7]
	,[Month 8],[Month 9],[Month 10],[Month 11],[Month 12],[Month 13],[Month 14]
	,[Month 15],[Month 16],[Month 17],[Month 18],[Month 19],[Month 20],[Month 21]
	,[Month 22],[Month 23],[Month 24],[Month 25],[Month 26],[Month 27],[Month 28]
	,[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
SELECT sn.scenario_id, @wbID, cp.company_number, bu.bu_number, jt.job_id
	,dp.dept_number, tm.hfm_team_code, lc.location_number, pd.hfm_product_code
	,COALESCE(plr.hfm_account_code,plh.hfm_account_code,ple.hfm_account_code,plb.hfm_account_code)
	,ct.category_id, t.[description], t.sheet_name, t.excel_row, t.forecast_method,t.forecast_rate
	,t.currency_code,t.[Month 1],t.[Month 2],t.[Month 3],t.[Month 4],t.[Month 5],t.[Month 6],t.[Month 7]
	,t.[Month 8],t.[Month 9],t.[Month 10],t.[Month 11],t.[Month 12],t.[Month 13],t.[Month 14]
	,t.[Month 15],t.[Month 16],t.[Month 17],t.[Month 18],t.[Month 19],t.[Month 20],t.[Month 21]
	,t.[Month 22],t.[Month 23],t.[Month 24],t.[Month 25],t.[Month 26],t.[Month 27],t.[Month 28]
	,t.[Month 29],t.[Month 30],t.[Month 31],t.[Month 32],t.[Month 33],t.[Month 34],t.[Month 35],t.[Month 36]
FROM @tbl t
LEFT JOIN BudgetDB.dbo.scenarios sn ON sn.scenario_name=ISNULL(t.scenario_name,'Forecast')
LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_name=t.company_name
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_name=t.bu_name
LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_name=t.dept_name
LEFT JOIN BudgetDB.dbo.teams tm ON tm.team_name=t.team_name
LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_name=t.location_name
LEFT JOIN BudgetDB.dbo.products pd ON pd.product_name=t.product_name
LEFT JOIN BudgetDB.dbo.job_titles jt ON jt.job_title=t.job_title
LEFT JOIN BudgetDB.dbo.divisions dv ON dv.bu_number=bu.bu_number
AND dv.dept_number=dp.dept_number
--	SPECIAL JOINS FOR HEADCOUNT/EXPENSES/REVENUE
--		(need to handle each all at once)
--	Revenue
LEFT JOIN BudgetDB.dbo.pl_items plr ON plr.pl_item=t.pl_item
AND plr.rollup_to_hosting_revenue IS NOT NULL
AND t.record_type='Revenue'
--	Expenses
LEFT JOIN BudgetDB.dbo.pl_items ple ON ple.pl_item=t.pl_item
AND ISNULL(ple.category_code,dv.category_code)=dv.category_code
AND t.record_type='Expenses' AND ple.rollup_to_hosting_revenue IS NULL
LEFT JOIN (
	SELECT pl_item, hfm_account_code, category_code
	FROM BudgetDB.dbo.pl_items
	WHERE pl_item IN ('Office Rent','Credit Card Fees','Commissions')
	AND category_code='G&A'
) plb ON plb.pl_item=t.pl_item
AND t.record_type='Expenses'
--	Headcount
LEFT JOIN BudgetDB.dbo.pl_items plh ON plh.pl_item=t.pl_item
AND t.record_type='Headcount' AND ple.rollup_to_hosting_revenue IS NULL
LEFT JOIN BudgetDB.dbo.categories ct ON ct.category_name=t.category
WHERE t.record_type IN ('Headcount','Revenue','Expenses')


--	delete cap rates for unused rows
DELETE cap
FROM BudgetDB.dbo.calculation_table_cap_rates cap
JOIN (
	SELECT lf.id
	FROM BudgetDB.dbo.live_forecast lf
	LEFT JOIN (
		SELECT DISTINCT workbook_id, sheet_name, excel_row
		FROM #TempMain
	) t ON t.workbook_id=lf.workbook_id
	AND t.sheet_name=lf.sheet_name
	AND t.excel_row=lf.excel_row
	WHERE lf.workbook_id=@wbID
	AND t.excel_row IS NULL
) f ON f.id=cap.id


--	delete unused rows for workbook
DELETE lf
FROM BudgetDB.dbo.live_forecast lf
LEFT JOIN #TempMain t
ON t.workbook_id=lf.workbook_id
AND t.sheet_name=lf.sheet_name
AND t.excel_row=lf.excel_row
WHERE lf.workbook_id=@wbID
AND t.excel_row IS NULL



MERGE BudgetDB.dbo.live_forecast lf
USING #TempMain t
ON t.workbook_id=lf.workbook_id AND t.sheet_name=lf.sheet_name
AND t.excel_row=lf.excel_row
WHEN MATCHED THEN
	UPDATE SET lf.scenario_id=t.scenario_id,lf.company_number=t.company_number,lf.bu_number=t.bu_number,lf.dept_number=t.dept_number
		,lf.hfm_team_code=t.hfm_team_code,lf.hfm_product_code=t.hfm_product_code
		,lf.location_number=t.location_number,lf.job_id=t.job_id,lf.hfm_account_code=t.hfm_account_code
		,lf.[Month 1]=t.[Month 1],lf.[Month 2]=t.[Month 2],lf.[Month 3]=t.[Month 3]
		,lf.[Month 4]=t.[Month 4],lf.[Month 5]=t.[Month 5],lf.[Month 6]=t.[Month 6]
		,lf.[Month 7]=t.[Month 7],lf.[Month 8]=t.[Month 8],lf.[Month 9]=t.[Month 9]
		,lf.[Month 10]=t.[Month 10],lf.[Month 11]=t.[Month 11],lf.[Month 12]=t.[Month 12]
		,lf.[Month 13]=t.[Month 13],lf.[Month 14]=t.[Month 14],lf.[Month 15]=t.[Month 15]
		,lf.[Month 16]=t.[Month 16],lf.[Month 17]=t.[Month 17],lf.[Month 18]=t.[Month 18]
		,lf.[Month 19]=t.[Month 19],lf.[Month 20]=t.[Month 20],lf.[Month 21]=t.[Month 21]
		,lf.[Month 22]=t.[Month 22],lf.[Month 23]=t.[Month 23],lf.[Month 24]=t.[Month 24]
		,lf.[Month 25]=t.[Month 25],lf.[Month 26]=t.[Month 26],lf.[Month 27]=t.[Month 27]
		,lf.[Month 28]=t.[Month 28],lf.[Month 29]=t.[Month 29],lf.[Month 30]=t.[Month 30]
		,lf.[Month 31]=t.[Month 31],lf.[Month 32]=t.[Month 32],lf.[Month 33]=t.[Month 33]
		,lf.[Month 34]=t.[Month 34],lf.[Month 35]=t.[Month 35],lf.[Month 36]=t.[Month 36]
		,lf.forecast_method=t.forecast_method, lf.forecast_rate=t.forecast_rate
		,lf.[description]=t.[description],lf.workbook_id=t.workbook_id,lf.currency_code=t.currency_code
		,lf.category_id=t.category_id,lf.sheet_name=t.sheet_name,lf.excel_row=t.excel_row
		,lf.last_updated_by=SYSTEM_USER,lf.last_updated_date=GETDATE()
WHEN NOT MATCHED THEN
	INSERT(scenario_id,company_number,bu_number,dept_number,hfm_team_code,location_number
		,hfm_product_code,job_id,hfm_account_code,category_id,[description],workbook_id
		,sheet_name,excel_row,forecast_method,forecast_rate,currency_code
		,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12]
		,[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18],[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
		,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
		,created_by,created_date,last_updated_by,last_updated_date)
	VALUES (t.scenario_id,t.company_number,t.bu_number,t.dept_number,t.hfm_team_code
		,t.location_number,t.hfm_product_code,t.job_id,t.hfm_account_code,t.category_id
		,t.[description],t.workbook_id,t.sheet_name,t.excel_row,t.forecast_method,t.forecast_rate,t.currency_code
		,t.[Month 1],t.[Month 2],t.[Month 3],t.[Month 4],t.[Month 5],t.[Month 6],t.[Month 7],t.[Month 8]
		,t.[Month 9],t.[Month 10],t.[Month 11],t.[Month 12],t.[Month 13],t.[Month 14],t.[Month 15],t.[Month 16]
		,t.[Month 17],t.[Month 18],t.[Month 19],t.[Month 20],t.[Month 21],t.[Month 22],t.[Month 23],t.[Month 24]
		,t.[Month 25],t.[Month 26],t.[Month 27],t.[Month 28],t.[Month 29],t.[Month 30],t.[Month 31]
		,t.[Month 32],t.[Month 33],t.[Month 34],t.[Month 35],t.[Month 36]
		,SYSTEM_USER,GETDATE(),SYSTEM_USER,GETDATE())
OUTPUT $action, t.sheet_name, t.excel_row, inserted.id INTO #TempOut;


---------------------------------
--	Cap Rates
--	select live_forecast ID value for each Headcount record
SELECT lf.id, lf.sheet_name, lf.excel_row
INTO #TempCap
FROM @tbl t
JOIN BudgetDB.dbo.live_forecast lf
ON lf.workbook_id=@wbID
AND lf.sheet_name=t.sheet_name
AND lf.excel_row=t.excel_row
AND t.record_type='Headcount'

MERGE BudgetDB.dbo.calculation_table_cap_rates cap
USING (
	SELECT tm.id, t.sheet_name, t.excel_row, @wbID workbook_id
		,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6]
		,[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12]
		,[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
		,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
		,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30]
		,[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
	FROM @tbl t
	LEFT JOIN #TempCap tm
	ON tm.sheet_name=t.sheet_name
	AND tm.excel_row=t.excel_row
	WHERE t.record_type='Cap Rate'
) t
ON t.id=cap.id
WHEN MATCHED THEN 
	UPDATE SET cap.[Month 1]=t.[Month 1],cap.[Month 2]=t.[Month 2],cap.[Month 3]=t.[Month 3]
		,cap.[Month 4]=t.[Month 4],cap.[Month 5]=t.[Month 5],cap.[Month 6]=t.[Month 6],cap.[Month 7]=t.[Month 7]
		,cap.[Month 8]=t.[Month 8],cap.[Month 9]=t.[Month 9],cap.[Month 10]=t.[Month 10],cap.[Month 11]=t.[Month 11]
		,cap.[Month 12]=t.[Month 12],cap.[Month 13]=t.[Month 13],cap.[Month 14]=t.[Month 14],cap.[Month 15]=t.[Month 15]
		,cap.[Month 16]=t.[Month 16],cap.[Month 17]=t.[Month 17],cap.[Month 18]=t.[Month 18],cap.[Month 19]=t.[Month 19]
		,cap.[Month 20]=t.[Month 20],cap.[Month 21]=t.[Month 21],cap.[Month 22]=t.[Month 22],cap.[Month 23]=t.[Month 23]
		,cap.[Month 24]=t.[Month 24],cap.[Month 25]=t.[Month 25],cap.[Month 26]=t.[Month 26],cap.[Month 27]=t.[Month 27]
		,cap.[Month 28]=t.[Month 28],cap.[Month 29]=t.[Month 29],cap.[Month 30]=t.[Month 30],cap.[Month 31]=t.[Month 31]
		,cap.[Month 32]=t.[Month 32],cap.[Month 33]=t.[Month 33],cap.[Month 34]=t.[Month 34]
		,cap.[Month 35]=t.[Month 35],cap.[Month 36]=t.[Month 36]
		,cap.last_updated_by=SYSTEM_USER,cap.last_updated_date=GETDATE()
WHEN NOT MATCHED THEN 
	INSERT (id,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6]
		,[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12]
		,[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
		,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
		,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30]
		,[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
		,created_by,created_date,last_updated_by,last_updated_date)
	VALUES (t.id,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6]
		,[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12]
		,[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
		,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
		,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30]
		,[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
		,SYSTEM_USER,GETDATE(),SYSTEM_USER,GETDATE())
OUTPUT $action, t.sheet_name, t.excel_row, inserted.id INTO #TempOut;

IF OBJECT_ID('tempdb..#TempCap') IS NOT NULL DROP TABLE #TempCap

---------------------------------
--	Commission Attainment
--	parse out relevant data
CREATE TABLE #Temp (
	[Month 1] DECIMAL(20,18) DEFAULT 1,[Month 2] DECIMAL(20,18) DEFAULT 1,[Month 3] DECIMAL(20,18) DEFAULT 1
	,[Month 4] DECIMAL(20,18) DEFAULT 1,[Month 5] DECIMAL(20,18) DEFAULT 1,[Month 6] DECIMAL(20,18) DEFAULT 1
	,[Month 7] DECIMAL(20,18) DEFAULT 1,[Month 8] DECIMAL(20,18) DEFAULT 1,[Month 9] DECIMAL(20,18) DEFAULT 1
	,[Month 10] DECIMAL(20,18) DEFAULT 1,[Month 11] DECIMAL(20,18) DEFAULT 1,[Month 12] DECIMAL(20,18) DEFAULT 1
	,[Month 13] DECIMAL(20,18) DEFAULT 1,[Month 14] DECIMAL(20,18) DEFAULT 1,[Month 15] DECIMAL(20,18) DEFAULT 1
	,[Month 16] DECIMAL(20,18) DEFAULT 1,[Month 17] DECIMAL(20,18) DEFAULT 1,[Month 18] DECIMAL(20,18) DEFAULT 1
	,[Month 19] DECIMAL(20,18) DEFAULT 1,[Month 20] DECIMAL(20,18) DEFAULT 1,[Month 21] DECIMAL(20,18) DEFAULT 1
	,[Month 22] DECIMAL(20,18) DEFAULT 1,[Month 23] DECIMAL(20,18) DEFAULT 1,[Month 24] DECIMAL(20,18) DEFAULT 1
	,[Month 25] DECIMAL(20,18) DEFAULT 1,[Month 26] DECIMAL(20,18) DEFAULT 1,[Month 27] DECIMAL(20,18) DEFAULT 1
	,[Month 28] DECIMAL(20,18) DEFAULT 1,[Month 29] DECIMAL(20,18) DEFAULT 1,[Month 30] DECIMAL(20,18) DEFAULT 1
	,[Month 31] DECIMAL(20,18) DEFAULT 1,[Month 32] DECIMAL(20,18) DEFAULT 1,[Month 33] DECIMAL(20,18) DEFAULT 1
	,[Month 34] DECIMAL(20,18) DEFAULT 1,[Month 35] DECIMAL(20,18) DEFAULT 1,[Month 36] DECIMAL(20,18) DEFAULT 1
)

INSERT INTO #Temp ([Month 1],[Month 2],[Month 3],[Month 4]
	,[Month 5],[Month 6],[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12],[Month 13],[Month 14]
	,[Month 15],[Month 16],[Month 17],[Month 18],[Month 19],[Month 20],[Month 21],[Month 22],[Month 23]
	,[Month 24],[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30],[Month 31],[Month 32]
	,[Month 33],[Month 34],[Month 35],[Month 36])
SELECT TOP 1 [Month 1],[Month 2],[Month 3],[Month 4]
	,[Month 5],[Month 6],[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12],[Month 13],[Month 14]
	,[Month 15],[Month 16],[Month 17],[Month 18],[Month 19],[Month 20],[Month 21],[Month 22],[Month 23]
	,[Month 24],[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30],[Month 31],[Month 32]
	,[Month 33],[Month 34],[Month 35],[Month 36]
FROM @tbl
WHERE record_type='Commission'

--	delete old attainment record
DELETE FROM BudgetDB.dbo.calculation_table_commission_attainment
WHERE scenario_id=@fcstID AND workbook_id=@wbID

--	insert new attainment record
INSERT INTO BudgetDB.dbo.calculation_table_commission_attainment (scenario_id, workbook_id,[Month 1],[Month 2],[Month 3],[Month 4]
	,[Month 5],[Month 6],[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12],[Month 13],[Month 14]
	,[Month 15],[Month 16],[Month 17],[Month 18],[Month 19],[Month 20],[Month 21],[Month 22],[Month 23]
	,[Month 24],[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30],[Month 31],[Month 32]
	,[Month 33],[Month 34],[Month 35],[Month 36])
SELECT @fcstID, @wbID,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6],[Month 7]
	,[Month 8],[Month 9],[Month 10],[Month 11],[Month 12],[Month 13],[Month 14],[Month 15],[Month 16]
	,[Month 17],[Month 18],[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24],[Month 25]
	,[Month 26],[Month 27],[Month 28],[Month 29],[Month 30],[Month 31],[Month 32],[Month 33],[Month 34]
	,[Month 35],[Month 36]
FROM #Temp

COMMIT TRANSACTION


--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

--	drop temp tables
IF OBJECT_ID('tempdb..#TempMain') IS NOT NULL DROP TABLE #TempMain
IF OBJECT_ID('tempdb..#Temp') IS NOT NULL DROP TABLE #Temp
IF OBJECT_ID('tempdb..#TempOut') IS NOT NULL DROP TABLE #TempOut
END TRY

BEGIN CATCH
--	rollback transactions
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

--	drop temp tables
IF OBJECT_ID('tempdb..#TempMain') IS NOT NULL DROP TABLE #TempMain
IF OBJECT_ID('tempdb..#Temp') IS NOT NULL DROP TABLE #Temp
IF OBJECT_ID('tempdb..#TempOut') IS NOT NULL DROP TABLE #TempOut
IF OBJECT_ID('tempdb..#TempCap') IS NOT NULL DROP TABLE #TempCap

--	prompt user with error message
SELECT 'Failure to update database:' + CHAR(13)+CHAR(10)
	+ ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO



EXEC sys.sp_dropextendedproperty @name = N'MS_Description'
	,@value = N'Stored procedure used by Excel VBA to upload all forecast '
		+ N'data from a workbook at once and updating the database tables as necessary'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'PROCEDURE'
	,@level1name = N'bulk_upload_excel_push_all_updates'
