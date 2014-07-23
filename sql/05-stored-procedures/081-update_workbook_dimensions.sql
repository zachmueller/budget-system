USE BudgetDB
GO

IF OBJECT_ID('dbo.update_workbook_dimensions', 'P') IS NOT NULL
	DROP PROCEDURE dbo.update_workbook_dimensions
GO


CREATE PROCEDURE dbo.update_workbook_dimensions
	@wbID INT
	,@companyList bulk_upload_name_list READONLY
	,@buList bulk_upload_name_list READONLY
	,@deptList bulk_upload_name_list READONLY
	,@teamList bulk_upload_name_list READONLY
	,@locList bulk_upload_name_list READONLY
	,@prodList bulk_upload_name_list READONLY
AS
/*
summary:	>
			Uploads an updated list of dimensions
			and applies them to the workbook-dimension
			mapping tables. The procedure first checks
			whether any of the removed dimensions are
			currently in use (i.e., in the
			dbo.live_forecast table) by the workbook
			and prevents the user from removing those
			dimensions.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

--	check that workbook exists
IF (SELECT COUNT(*) FROM BudgetDB.dbo.workbooks
	WHERE workbook_id=@wbID) = 0
BEGIN
	SELECT 'Workbook ID not found in the database' o
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
		SELECT 'Company' dim, t.name item, 'Invalid' er
		FROM @companyList t
		LEFT JOIN BudgetDB.dbo.companies cp ON cp.company_name=t.name
		WHERE cp.company_number IS NULL
		AND t.name <> 'INCLUDE ALL'
		UNION
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
	
	--	update CONTEXT_INFO for trigger
	DECLARE @ci VARBINARY(128) = CAST('sproc:update_workbook_dimensions' AS VARBINARY(128))
	SET CONTEXT_INFO @ci
	
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
	
	
	--	check whether any data exists in live forecast related to removed items
	CREATE TABLE #TempRemoveErrors (
		item NVARCHAR(256)
		,item_name NVARCHAR(256)
		,item_number NVARCHAR(256)
	)
	
	IF (SELECT TOP 1 company_number FROM #TempCompanies) IS NOT NULL
	BEGIN
		INSERT INTO #TempRemoveErrors (item, item_name, item_number)
		SELECT DISTINCT 'Companies' item, cp.company_name item_name, cp.company_number item_number
		FROM BudgetDB.dbo.companies cp
		LEFT JOIN #TempCompanies tcp
		ON tcp.company_number=cp.company_number
		LEFT JOIN BudgetDB.dbo.live_forecast lf
		ON lf.company_number=cp.company_number
		WHERE lf.workbook_id=@wbID
			AND tcp.company_number IS NULL
			AND lf.company_number IS NOT NULL
	END
	
	IF (SELECT TOP 1 bu_number FROM #TempBUs) IS NOT NULL
	BEGIN
		INSERT INTO #TempRemoveErrors (item, item_name, item_number)
		SELECT DISTINCT 'Business Units' item, bu.bu_name item_name, bu.bu_number item_number
		FROM BudgetDB.dbo.business_units bu
		LEFT JOIN #TempBUs tbu
		ON tbu.bu_number=bu.bu_number
		LEFT JOIN BudgetDB.dbo.live_forecast lf
		ON lf.bu_number=bu.bu_number
		WHERE lf.workbook_id=@wbID
			AND tbu.bu_number IS NULL
			AND lf.bu_number IS NOT NULL
	END
	
	IF (SELECT TOP 1 dept_number FROM #TempDepts) IS NOT NULL
	BEGIN
		INSERT INTO #TempRemoveErrors (item, item_name, item_number)
		SELECT DISTINCT 'Departments' item, dp.dept_name item_name, dp.dept_number item_number
		FROM BudgetDB.dbo.departments dp
		LEFT JOIN #TempDepts tdp
		ON tdp.dept_number=dp.dept_number
		LEFT JOIN BudgetDB.dbo.live_forecast lf
		ON lf.dept_number=dp.dept_number
		WHERE lf.workbook_id=@wbID
			AND tdp.dept_number IS NULL
			AND lf.dept_number IS NOT NULL
	END
	
	IF (SELECT TOP 1 hfm_team_code FROM #TempTeams) IS NOT NULL
	BEGIN
		INSERT INTO #TempRemoveErrors (item, item_name, item_number)
		SELECT DISTINCT 'Teams' item, tm.team_name item_name, tm.hfm_team_code item_number
		FROM BudgetDB.dbo.teams tm
		LEFT JOIN #TempTeams ttm
		ON ttm.hfm_team_code=tm.hfm_team_code
		LEFT JOIN BudgetDB.dbo.live_forecast lf
		ON lf.hfm_team_code=tm.hfm_team_code
		WHERE lf.workbook_id=@wbID
			AND ttm.hfm_team_code IS NULL
			AND lf.hfm_team_code IS NOT NULL
	END
	
	IF (SELECT TOP 1 location_number FROM #TempLocs) IS NOT NULL
	BEGIN
		INSERT INTO #TempRemoveErrors (item, item_name, item_number)
		SELECT DISTINCT 'Locations' item, lc.location_name item_name, lc.location_number item_number
		FROM BudgetDB.dbo.locations lc
		LEFT JOIN #TempLocs tlc
		ON tlc.location_number=lc.location_number
		LEFT JOIN BudgetDB.dbo.live_forecast lf
		ON lf.location_number=lc.location_number
		WHERE lf.workbook_id=@wbID
			AND tlc.location_number IS NULL
			AND lf.location_number IS NOT NULL
	END
	
	IF (SELECT TOP 1 hfm_product_code FROM #TempProds) IS NOT NULL
	BEGIN
		INSERT INTO #TempRemoveErrors (item, item_name, item_number)
		SELECT DISTINCT 'Products' item, pd.product_name item_name, pd.hfm_product_code item_number
		FROM BudgetDB.dbo.products pd
		LEFT JOIN #TempProds tpd
		ON tpd.hfm_product_code=pd.hfm_product_code
		LEFT JOIN BudgetDB.dbo.live_forecast lf
		ON lf.hfm_product_code=pd.hfm_product_code
		WHERE lf.workbook_id=@wbID
			AND tpd.hfm_product_code IS NULL
			AND lf.hfm_product_code IS NOT NULL
	END
	
	
	--	add any "remove error" items into the temp tables
	--		to make all other updates besides the errored out changes
	INSERT INTO #TempCompanies
	SELECT item_number
	FROM #TempRemoveErrors
	WHERE item='Companies'
	
	INSERT INTO #TempBUs
	SELECT item_number
	FROM #TempRemoveErrors
	WHERE item='Business Units'
	
	INSERT INTO #TempDepts
	SELECT item_number
	FROM #TempRemoveErrors
	WHERE item='Departments'
	
	INSERT INTO #TempTeams
	SELECT item_number
	FROM #TempRemoveErrors
	WHERE item='Teams'
	
	INSERT INTO #TempLocs
	SELECT item_number
	FROM #TempRemoveErrors
	WHERE item='Locations'
	
	INSERT INTO #TempProds
	SELECT item_number
	FROM #TempRemoveErrors
	WHERE item='Products'
	
	BEGIN TRANSACTION
	
	--	merge temp tables with permanent tables
	MERGE BudgetDB.dbo.workbook_companies wb
	USING #TempCompanies t
	ON t.company_number=wb.company_number
	AND wb.workbook_id=@wbID
	WHEN NOT MATCHED BY SOURCE AND wb.workbook_id=@wbID THEN
		DELETE
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (workbook_id, company_number)
		VALUES (@wbID, t.company_number);
	
	MERGE BudgetDB.dbo.workbook_business_units wb
	USING #TempBUs t
	ON t.bu_number=wb.bu_number
	AND wb.workbook_id=@wbID
	WHEN NOT MATCHED BY SOURCE AND wb.workbook_id=@wbID THEN
		DELETE
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (workbook_id, bu_number)
		VALUES (@wbID, t.bu_number);
	
	MERGE BudgetDB.dbo.workbook_departments wb
	USING #TempDepts t
	ON t.dept_number=wb.dept_number
	AND wb.workbook_id=@wbID
	WHEN NOT MATCHED BY SOURCE AND wb.workbook_id=@wbID THEN
		DELETE
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (workbook_id, dept_number)
		VALUES (@wbID, t.dept_number);
	
	MERGE BudgetDB.dbo.workbook_teams wb
	USING #TempTeams t
	ON t.hfm_team_code=wb.hfm_team_code
	AND wb.workbook_id=@wbID
	WHEN NOT MATCHED BY SOURCE AND wb.workbook_id=@wbID THEN
		DELETE
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (workbook_id, hfm_team_code)
		VALUES (@wbID, t.hfm_team_code);
	
	MERGE BudgetDB.dbo.workbook_locations wb
	USING #TempLocs t
	ON t.location_number=wb.location_number
	AND wb.workbook_id=@wbID
	WHEN NOT MATCHED BY SOURCE AND wb.workbook_id=@wbID THEN
		DELETE
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (workbook_id, location_number)
		VALUES (@wbID, t.location_number);
	
	MERGE BudgetDB.dbo.workbook_products wb
	USING #TempProds t
	ON t.hfm_product_code=wb.hfm_product_code
	AND wb.workbook_id=@wbID
	WHEN NOT MATCHED BY SOURCE AND wb.workbook_id=@wbID THEN
		DELETE
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (workbook_id, hfm_product_code)
		VALUES (@wbID, t.hfm_product_code);
	
	COMMIT TRANSACTION
	
	IF ((SELECT COUNT(*) FROM #TempRemoveErrors) > 0)
	BEGIN	--	remove errors found
		SELECT DISTINCT item, item_name
		FROM #TempRemoveErrors
	END
	ELSE
	BEGIN
		SELECT 'Workbook successfully updated.' o
	END
	
	--	set CONTEXT_INFO back to NULL
	SET CONTEXT_INFO 0x
	
END TRY

BEGIN CATCH
--	rollback transaction and drop temp tables
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

IF OBJECT_ID('tempdb..#TempRemoveErrors') IS NOT NULL DROP TABLE #TempRemoveErrors
IF OBJECT_ID('tempdb..#TempWorkbook') IS NOT NULL DROP TABLE #TempWorkbook
IF OBJECT_ID('tempdb..#TempCompanies') IS NOT NULL DROP TABLE #TempCompanies
IF OBJECT_ID('tempdb..#TempBUs') IS NOT NULL DROP TABLE #TempBUs
IF OBJECT_ID('tempdb..#TempDepts') IS NOT NULL DROP TABLE #TempDepts
IF OBJECT_ID('tempdb..#TempTeams') IS NOT NULL DROP TABLE #TempTeams
IF OBJECT_ID('tempdb..#TempLocs') IS NOT NULL DROP TABLE #TempLocs
IF OBJECT_ID('tempdb..#TempProds') IS NOT NULL DROP TABLE #TempProds
--	return error message to user
SELECT 'An error occurred in the database while attemping to update the Workbook:' + CHAR(13)+CHAR(10) 
	+ ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
