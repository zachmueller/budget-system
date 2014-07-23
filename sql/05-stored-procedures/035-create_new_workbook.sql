USE BudgetDB
GO

IF OBJECT_ID('dbo.create_new_workbook', 'P') IS NOT NULL
	DROP PROCEDURE dbo.create_new_workbook
GO


CREATE PROCEDURE dbo.create_new_workbook
	@workbookName NVARCHAR(256)
	,@workbookLocation NVARCHAR(2048)
	,@companyList bulk_upload_name_list READONLY
	,@buList bulk_upload_name_list READONLY
	,@deptList bulk_upload_name_list READONLY
	,@teamList bulk_upload_name_list READONLY
	,@locList bulk_upload_name_list READONLY
	,@prodList bulk_upload_name_list READONLY
	,@outputOnly BIT
	,@usIntl BIT = NULL
AS
/*
summary:	>
			Used by analysts to formally create
			new workbooks (either forecast or rollup)
			providing lists of dimensions and
			whether the workbook is US, INTL,
			or both.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

DECLARE @wbID as INT

--	check whether workbook name has already been used
IF EXISTS (SELECT workbook_id FROM BudgetDB.dbo.workbooks WHERE workbook_name=@workbookName)
BEGIN	--	Stop procedure if name already exists
	SELECT 'Workbook name already exists, please try a different name.'
	RETURN
END


BEGIN TRY
	--	Create list temp tables
	CREATE TABLE #TempCompanies (
		company_number NCHAR(3)
	)
	CREATE TABLE #TempBUs (
		bu_number NVARCHAR(100)
	)
	CREATE TABLE #TempDepts (
		dept_number NCHAR(4)
	)
	CREATE TABLE #TempTeams (
		hfm_team_code NVARCHAR(100)
	)
	CREATE TABLE #TempLocs (
		location_number NCHAR(3)
	)
	CREATE TABLE #TempProds (
		hfm_product_code NVARCHAR(100)
	)
	
	--	Validate upload data
	SELECT dim dimension, item item_name, er error_type
	INTO #TempErrors 
	FROM (
		--	check for invalid company names
		SELECT 'Company' dim, t.name item, 'Invalid' er
		FROM @companyList t
		LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_name=t.name
		WHERE cp.company_number IS NULL
		AND t.name <> 'INCLUDE ALL'
		UNION
		--	check for inactive company names
		SELECT 'Company' dim, t.name item, 'Inactive' er
		FROM @companyList t
		LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_name=t.name
		WHERE cp.active_forecast_option=0
		AND t.name <> 'INCLUDE ALL'
		UNION
		
		SELECT 'BU' dim, t.name item, 'Invalid' er
		FROM @buList t
		LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_name=t.name
		WHERE bu.bu_number IS NULL
		AND t.name <> 'INCLUDE ALL'
		UNION
		SELECT 'BU' dim, t.name item, 'Inactive' er
		FROM @buList t
		LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_name=t.name
		WHERE bu.active_forecast_option=0
		AND t.name <> 'INCLUDE ALL'
		UNION
		
		SELECT 'Department' dim, t.name item, 'Invalid' er
		FROM @deptList t
		LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_name=t.name
		WHERE dp.dept_number IS NULL
		AND t.name <> 'INCLUDE ALL'
		UNION
		SELECT 'Department' dim, t.name item, 'Inactive' er
		FROM @deptList t
		LEFT JOIN BudgetDB.dbo.departments dp ON dp.dept_name=t.name
		WHERE dp.active_forecast_option=0
		AND t.name <> 'INCLUDE ALL'
		UNION
		
		SELECT 'Team' dim, t.name item, 'Invalid' er
		FROM @teamList t
		LEFT JOIN BudgetDB.dbo.teams tm ON tm.team_consolidation=t.name
		WHERE tm.hfm_team_code IS NULL
		AND t.name <> 'INCLUDE ALL'
		UNION
		SELECT 'Team' dim, t.name item, 'Inactive' er
		FROM @teamList t
		LEFT JOIN BudgetDB.dbo.teams tm ON tm.team_consolidation=t.name
		WHERE tm.active_forecast_option=0
		AND t.name <> 'INCLUDE ALL'
		UNION
		
		SELECT 'Location' dim, t.name item, 'Invalid' er
		FROM @locList t
		LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_name=t.name
		WHERE lc.location_number IS NULL
		AND t.name <> 'INCLUDE ALL'
		UNION
		SELECT 'Location' dim, t.name item, 'Inactive' er
		FROM @locList t
		LEFT JOIN BudgetDB.dbo.locations lc ON lc.location_name=t.name
		WHERE lc.active_forecast_option=0
		AND t.name <> 'INCLUDE ALL'
		UNION
		
		SELECT 'Product' dim, t.name item, 'Invalid' er
		FROM @prodList t
		LEFT JOIN BudgetDB.dbo.products pd ON pd.product_name=t.name
		WHERE pd.hfm_product_code IS NULL
		AND t.name <> 'INCLUDE ALL'
		UNION
		SELECT 'Product' dim, t.name item, 'Inactive' er
		FROM @prodList t
		LEFT JOIN BudgetDB.dbo.products pd ON pd.product_name=t.name
		WHERE pd.active_forecast_option=0
		AND t.name <> 'INCLUDE ALL'
	) a
	
	--	If errors exist, list them out and stop stored procedure
	IF (SELECT COUNT(*)
		FROM #TempErrors) > 0
	BEGIN
		SELECT TOP 15 dimension + ': ' + item_name + ' (' + error_type + ')' er
		FROM #TempErrors
		
		RETURN
	END
	
	--	Fill temp tables with inputs
	INSERT INTO #TempCompanies (company_number)
	SELECT cp.company_number
	FROM @companyList cpl
	LEFT JOIN BudgetDB.dbo.companies cp
	ON cp.company_name=cpl.name
	
	INSERT INTO #TempBUs (bu_number)
	SELECT bu.bu_number
	FROM @buList bul
	LEFT JOIN BudgetDB.dbo.business_units bu
	ON bu.bu_name=bul.name
	
	INSERT INTO #TempDepts (dept_number)
	SELECT dp.dept_number
	FROM @deptList dpl
	LEFT JOIN BudgetDB.dbo.departments dp
	ON dp.dept_name=dpl.name
	
	INSERT INTO #TempTeams (hfm_team_code)
	SELECT tm.hfm_team_code
	FROM @teamList tml
	LEFT JOIN BudgetDB.dbo.teams tm
	ON ISNULL(tm.team_consolidation,tm.team_name)=tml.name
	
	INSERT INTO #TempLocs (location_number)
	SELECT lc.location_number
	FROM @locList lcl
	LEFT JOIN BudgetDB.dbo.locations lc
	ON lc.location_name=lcl.name
	
	INSERT INTO #TempProds (hfm_product_code)
	SELECT pd.hfm_product_code
	FROM @prodList pdl
	LEFT JOIN BudgetDB.dbo.products pd
	ON ISNULL(pd.product_consolidation,pd.product_name)=pdl.name
	
	--	create workbook temp table
	CREATE TABLE #TempWorkbook (
		workbook_name NVARCHAR(256)
		,workbook_location NVARCHAR(2048)
	)
	CREATE TABLE #TempID (
		workbook_id INT
	)
	
	INSERT INTO #TempWorkbook (workbook_name, workbook_location)
	VALUES (@workbookName, @workbookLocation)
	
	BEGIN TRANSACTION
	
	--	update CONTEXT_INFO for trigger
	DECLARE @ci VARBINARY(128) = CAST('sproc:create_new_workbook' AS VARBINARY(128))
	SET CONTEXT_INFO @ci
	
	--	add workbook to workbooks table
	MERGE BudgetDB.dbo.workbooks wb
	USING #TempWorkbook twb
	ON twb.workbook_name=wb.workbook_name
	WHEN NOT MATCHED THEN
		INSERT (workbook_name, workbook_location, output_only
			,created_by, created_date, us_0_intl_1)
		VALUES (twb.workbook_name, twb.workbook_location
			,@outputOnly, SYSTEM_USER, GETDATE(), @usIntl)
	--	Capture new workbook ID
	OUTPUT inserted.workbook_id INTO #TempID;
	
	--	get new workbook ID value
	SET @wbID = (SELECT TOP 1 workbook_id FROM #TempID)
	DROP TABLE #TempID
	DROP TABLE #TempWorkbook
	
	--	insert values from lists
	INSERT INTO BudgetDB.dbo.workbook_companies (workbook_id, company_number)
	SELECT @wbID, company_number
	FROM #TempCompanies
	
	INSERT INTO BudgetDB.dbo.workbook_business_units (workbook_id, bu_number)
	SELECT @wbID, bu_number
	FROM #TempBUs
	
	INSERT INTO BudgetDB.dbo.workbook_departments (workbook_id, dept_number)
	SELECT @wbID, dept_number
	FROM #TempDepts
	
	INSERT INTO BudgetDB.dbo.workbook_teams (workbook_id, hfm_team_code)
	SELECT @wbID, hfm_team_code
	FROM #TempTeams
	
	INSERT INTO BudgetDB.dbo.workbook_locations (workbook_id, location_number)
	SELECT @wbID, location_number
	FROM #TempLocs
	
	INSERT INTO BudgetDB.dbo.workbook_products (workbook_id, hfm_product_code)
	SELECT @wbID, hfm_product_code
	FROM #TempProds
	
	COMMIT TRANSACTION
	
	--	grab currency code for a company in new workbook
	--		for filling a default currency in the workbook
	SELECT TOP 1 cp.currency_code
	INTO #TempCurrency
	FROM BudgetDB.dbo.workbook_companies wbcp
	LEFT JOIN BudgetDB.dbo.companies cp
	ON cp.company_number=ISNULL(wbcp.company_number,cp.company_number)
	
	-- inform user of successful creation
	SELECT TOP 1 'Successfully updated the database for the new workbook.' o
		,@wbID wb_id, currency_code
	FROM #TempCurrency
	
	--	set CONTEXT_INFO back to NULL
	SET CONTEXT_INFO 0x
	
END TRY

BEGIN CATCH
--	rollback transaction and drop temp tables
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

IF OBJECT_ID('tempdb..#TempID') IS NOT NULL DROP TABLE #TempID
IF OBJECT_ID('tempdb..#TempWorkbook') IS NOT NULL DROP TABLE #TempWorkbook
IF OBJECT_ID('tempdb..#TempCompanies') IS NOT NULL DROP TABLE #TempCompanies
IF OBJECT_ID('tempdb..#TempBUs') IS NOT NULL DROP TABLE #TempBUs
IF OBJECT_ID('tempdb..#TempDepts') IS NOT NULL DROP TABLE #TempDepts
IF OBJECT_ID('tempdb..#TempTeams') IS NOT NULL DROP TABLE #TempTeams
IF OBJECT_ID('tempdb..#TempLocs') IS NOT NULL DROP TABLE #TempLocs
IF OBJECT_ID('tempdb..#TempProds') IS NOT NULL DROP TABLE #TempProds
--	return error message to user
SELECT 'An error occurred in the database while attemping to create the new Workbook:' + CHAR(13)+CHAR(10) 
	+ ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
