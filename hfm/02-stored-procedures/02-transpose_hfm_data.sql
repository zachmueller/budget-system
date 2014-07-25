USE HFM_ActualsDB
GO

IF OBJECT_ID('dbo.transpose_hfm_data', 'P') IS NOT NULL
	DROP PROCEDURE dbo.transpose_hfm_data
GO


CREATE PROCEDURE dbo.transpose_hfm_data
AS
/*
summary:	>
			Take the HFM data, from the Extended
			Analytics data dump, and transpose
			it into a form compatible with the
			budget system.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-25
*/
SET NOCOUNT ON

--	create variables for tracking count in lock table
--	HFM inserts records into this table while pushing
--		data into SQL and removes the record once completed
DECLARE @i INT = (SELECT COUNT(*) FROM HFM_ActualsDB.dbo.HFM_LOCK_ACCESS WITH (NOLOCK))
	,@n INT = 0	--	additional variable to limit length of checking loop

--	loop to check that HFM LOCK table is cleared
WHILE ( @i > 0  AND  @n < 25 )
BEGIN
	--	wait 30 seconds between checks
	WAITFOR DELAY '00:00:30'
	
	--	increment counter
	SET @n = @n + 1
	
	--	update counter variable
	SET @i = (SELECT COUNT(*)
		FROM HFM_ActualsDB.dbo.HFM_LOCK_ACCESS WITH (NOLOCK))
END


--	capture run time
DECLARE @triggerFireDate DATETIME2 = GETDATE()

--	update CONTEXT_INFO for BudgetDB triggers
DECLARE @ci VARBINARY(128) = CAST('sproc:HFM_ActualsDB.dbo.transpose_hfm_data' AS VARBINARY(128))
SET CONTEXT_INFO @ci

--	error handling with TRY..CATCH
BEGIN TRY
BEGIN TRANSACTION
--	merge HFM entity table with companies
--	Create a temporary hierarchy table to define the parent-child
--		relationships, maintaining the child's description (name)
SELECT DISTINCT label child, parentlabel parent, description company_name
INTO #TempEntityParentChild
FROM HFM_ActualsDB.dbo.PROD_ENTITY

--	Define a list to differentiate between US and International,
--		using members in the HFM hierarchy
SELECT parent
INTO #TempUsIntl
FROM (	SELECT 'US' parent UNION
		SELECT 'INTL' parent) a

; WITH baseMembers AS (
	--	ANCHOR MEMBER DEFINITION
	--		Starting with the hierarchy table, filter down
	--		to records where the Parent exists in the
	--		desired final parent list (US vs. Intl)
	SELECT sourceTable.child, sourceTable.company_name, sourceTable.parent direct_parent
		,sourceTable.parent top_parent
	FROM #TempEntityParentChild sourceTable
	JOIN #TempUsIntl finalList
		ON finalList.parent=sourceTable.parent
	UNION ALL
	--	RECURSIVE MEMBER DEFINITION
	--		Start, again, with the same hierarchy source table, unfiltered
	SELECT sourceTable.child, sourceTable.company_name, sourceTable.parent direct_parent
		--	The top_parent from the previous iteration's set is pulled
		--		to maintain the US/INTL distinction throughout the iterations
		,recursiveSet.top_parent top_parent
	FROM #TempEntityParentChild sourceTable
	--	Recursively join the prior iteration of the set where the
	--		child from the previous set matches the parent of
	--		the joined-again source table
	INNER JOIN baseMembers recursiveSet
		ON recursiveSet.child=sourceTable.parent
)--		Select out the number, name, and US/Intl value for each company
--		that matches the pattern of 3 character length and is numeric
SELECT child company_number, company_name, top_parent us_intl
INTO #TempCompany
FROM baseMembers
WHERE LEN(child)=3 AND ISNUMERIC(child)=1

--	combine tables and fill in currency code
SELECT tc.company_number, tc.company_name, CASE WHEN tc.us_intl='US' THEN 0 ELSE 1 END us_intl, cc.currency_code
INTO #TempCompanies
FROM #TempCompany tc
LEFT JOIN (
	SELECT DISTINCT en.label company_number, vl.label currency_code
	FROM HFM_ActualsDB.dbo.PROD_ENTITY en
	LEFT JOIN HFM_ActualsDB.dbo.PROD_VALUE vl
	ON vl.ID=en.DefaultCurrency
) cc ON cc.company_number=tc.company_number

--	create temp table to capture records updated
CREATE TABLE #Temp (
	action_taken NVARCHAR(50)
)

MERGE BudgetDB.dbo.companies cp
USING #TempCompanies tc
ON tc.company_number=cp.company_number
WHEN MATCHED THEN
	UPDATE SET cp.hfm_company_description=tc.company_name
WHEN NOT MATCHED THEN
	INSERT (company_number, company_name, currency_code, active_forecast_option
		,hfm_company_description, us_0_intl_1)
	VALUES (company_number, company_name, currency_code, 0, company_name, us_intl)
OUTPUT $action INTO #Temp;

--	add to trigger_log table
INSERT INTO HFM_ActualsDB.dbo.trigger_log (trigger_name, trigger_run_date, table_name
	,rows_inserted, rows_updated, rows_deleted)
VALUES ('tr_hfm_entity', @triggerFireDate, 'BudgetDB.dbo.companies'
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='INSERT')
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='UPDATE'), 0)

--	drop temp tables
IF OBJECT_ID('tempdb..#TempEntityParentChild') IS NOT NULL DROP TABLE #TempEntityParentChild
IF OBJECT_ID('tempdb..#TempUsIntl') IS NOT NULL DROP TABLE #TempUsIntl
IF OBJECT_ID('tempdb..#TempCompany') IS NOT NULL DROP TABLE #TempCompany
IF OBJECT_ID('tempdb..#TempCompanies') IS NOT NULL DROP TABLE #TempCompanies
DELETE FROM #Temp



--	merge HFM entity table with locations
--	store in a temp table the member labels and descriptions (names)
--		that fall 2 levels under the LOCATIONS parent, excluding ICP members
SELECT label, [description]
INTO #TempLocationParents
FROM HFM_ActualsDB.dbo.PROD_ENTITY
WHERE ParentLabel IN (
	SELECT label FROM HFM_ActualsDB.dbo.PROD_ENTITY
	WHERE ParentLabel='LOCATIONS' AND label<>'ICP')

--	Fill the final Locations temp table with the first location number [RIGHT(label,3)]
--		found in the next level below the previous query. Pull in the description
--		from the prior query as the location name
SELECT location_number, location_name, real_location
INTO #TempLocations
FROM (
	SELECT DISTINCT RIGHT(e.label,3) location_number, tl.[description] location_name
		,CASE WHEN ISNUMERIC(RIGHT(e.label,3))=0 THEN 0 ELSE 1 END real_location
	FROM HFM_ActualsDB.dbo.PROD_ENTITY e
	LEFT JOIN #TempLocationParents tl ON tl.label=e.parentlabel
	WHERE parentlabel IN (SELECT label FROM #TempLocationParents)
	UNION
	--	Additionally include ICP "locations", but designate as non-real locations
	SELECT location_number, location_name, real_location
	FROM (
		SELECT DISTINCT RIGHT(label,3) location_number
			,SUBSTRING([description],CHARINDEX(' - ',[description])+3,LEN([description])) location_name
			,0 real_location, ROW_NUMBER() OVER (PARTITION BY RIGHT(label,3) ORDER BY RIGHT(label,3) ASC) RN
		FROM HFM_ActualsDB.dbo.PROD_ENTITY
		WHERE parentlabel='ICP' AND CHARINDEX(' - ',[description])<>0
	) a WHERE RN=1
) a

--	merge with BudgetDB locations table
MERGE BudgetDB.dbo.locations lc
USING #TempLocations tc
ON tc.location_number=lc.location_number
WHEN MATCHED THEN
	UPDATE SET lc.hfm_location_description=tc.location_name
WHEN NOT MATCHED THEN
	INSERT (location_number, location_name, active_forecast_option
		,real_location, hfm_location_description)
	VALUES (tc.location_number, NULL, 0, tc.real_location, tc.location_name)
OUTPUT $action INTO #Temp;

--	update Actuals date (set to prior month from execution date)
UPDATE BudgetDB.dbo.scenarios
SET start_date=DATEADD(m,-1,DATEADD(m,DATEDIFF(m,0,getdate()),0))
WHERE scenario_name='Actual'

--	add to trigger_log table
INSERT INTO HFM_ActualsDB.dbo.trigger_log (trigger_name, trigger_run_date, table_name
	,rows_inserted, rows_updated, rows_deleted)
VALUES ('tr_hfm_entity', @triggerFireDate, 'BudgetDB.dbo.locations'
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='INSERT')
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='UPDATE'), 0)

--	drop temp tables
IF OBJECT_ID('tempdb..#TempLocationParents') IS NOT NULL DROP TABLE #TempLocationParents
IF OBJECT_ID('tempdb..#TempLocations') IS NOT NULL DROP TABLE #TempLocations
COMMIT TRANSACTION
END TRY


BEGIN CATCH
--	rollback transaction
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
--	insert error thrown into the trigger_error_log
INSERT INTO HFM_ActualsDB.dbo.trigger_error_log (trigger_name, trigger_run_date, error_message)
VALUES ('tr_hfm_entity', @triggerFireDate, ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2)))
END CATCH




---------------------------------------------------------------
SET @triggerFireDate = GETDATE()
--	error handling with TRY..CATCH
BEGIN TRY
BEGIN TRANSACTION

--	fill parent-child temp table
SELECT DISTINCT label child, parentlabel parent
INTO #TempCustom1ParentChild
FROM HFM_ActualsDB.dbo.PROD_CUSTOM1

--	find all active BUs
SELECT label bu_number, [description] bu_name
INTO #TempActiveBUs
FROM HFM_ActualsDB.dbo.PROD_CUSTOM1
WHERE parentlabel='BU_DIV_DEPT'

--	find departments
SELECT DISTINCT RIGHT(label,4) dept_number, [description] dept_name
INTO #TempDepartments
FROM HFM_ActualsDB.dbo.PROD_CUSTOM1
WHERE LEN(label)=9 AND ISNUMERIC(LEFT(label,4)+RIGHT(label,4))=1


--	divisions: need bu_number, dept_number, division_name
SELECT label division_code, [description] division_name
INTO #TempDivisionNames
FROM HFM_ActualsDB.dbo.PROD_CUSTOM1
WHERE parentlabel='DIVISION'

; WITH baseMembers AS (
	--	ANCHOR MEMBER DEFINITION
	--		Starting with the hierarchy table, filter down
	--		to records where the Parent exists in the
	--		desired final parent list (division)
	SELECT sourceTable.child, sourceTable.parent direct_parent
		,sourceTable.parent top_parent
	FROM #TempCustom1ParentChild sourceTable
	JOIN #TempDivisionNames finalList
		ON finalList.division_code=sourceTable.parent
	WHERE finalList.division_code<>'HISTORICAL'
	
	UNION ALL
	
	--	RECURSIVE MEMBER DEFINITION
	--		Start, again, with the same hierarchy source table, unfiltered
	SELECT sourceTable.child, sourceTable.parent direct_parent
		--	The top_parent from the previous iteration's set is pulled
		--		to maintain the division mapping throughout the iterations
		,recursiveSet.top_parent top_parent
	FROM #TempCustom1ParentChild sourceTable
	--	Recursively join the prior iteration of the set where the
	--		child from the previous set matches the parent of
	--		the joined-again source table
	INNER JOIN baseMembers recursiveSet
		ON recursiveSet.child=sourceTable.parent
)
--	Select out the numbers and division code for each BU/Dept
SELECT LEFT(child,4) bu_number, RIGHT(child,4) dept_number, top_parent division_code
INTO #TempDivisions
FROM baseMembers
WHERE LEN(child)=9 AND ISNUMERIC(LEFT(child,4)+RIGHT(child,4))=1

--	metrics
SELECT label metric_code, [description] metric_name
INTO #TempMetricNames
FROM HFM_ActualsDB.dbo.PROD_CUSTOM1
WHERE parentlabel='METRICS'

; WITH baseMembers AS (
	--	ANCHOR MEMBER DEFINITION
	--		Starting with the hierarchy table, filter down
	--		to records where the Parent exists in the
	--		desired final parent list (metric)
	SELECT sourceTable.child, sourceTable.parent direct_parent
		,sourceTable.parent top_parent
	FROM #TempCustom1ParentChild sourceTable
	JOIN #TempMetricNames finalList
		ON finalList.metric_code=sourceTable.parent
	WHERE finalList.metric_code<>'NON METRICS'
	UNION ALL
	--	RECURSIVE MEMBER DEFINITION
	--		Start, again, with the same hierarchy source table, unfiltered
	SELECT sourceTable.child, sourceTable.parent direct_parent
		--	The top_parent from the previous iteration's set is pulled
		--		to maintain the metrics throughout the iterations
		,recursiveSet.top_parent top_parent
	FROM #TempCustom1ParentChild sourceTable
	--	Recursively join the prior iteration of the set where the
	--		child from the previous set matches the parent of
	--		the joined-again source table
	INNER JOIN baseMembers recursiveSet
		ON recursiveSet.child=sourceTable.parent
)
--	Select out the numbers and metric code for each BU/Dept
SELECT LEFT(child,4) bu_number, RIGHT(child,4) dept_number, top_parent metric_code
INTO #TempMetrics FROM baseMembers
WHERE LEN(child)=9 AND ISNUMERIC(LEFT(child,4)+RIGHT(child,4))=1

--	P&L cateogry
SELECT label category_code, [description] category_name
INTO #TempCategoryNames
FROM HFM_ActualsDB.dbo.PROD_CUSTOM1
WHERE parentlabel='CATEGORY'

; WITH baseMembers AS (
	--	ANCHOR MEMBER DEFINITION
	--		Starting with the hierarchy table, filter down
	--		to records where the Parent exists in the
	--		desired final parent list (category)
	SELECT sourceTable.child, sourceTable.parent direct_parent
		,sourceTable.parent top_parent
	FROM #TempCustom1ParentChild sourceTable
	JOIN #TempCategoryNames finalList
		ON finalList.category_code=sourceTable.parent
	WHERE finalList.category_code<>'HIST_BU'
	UNION ALL
	--	RECURSIVE MEMBER DEFINITION
	--		Start, again, with the same hierarchy source table, unfiltered
	SELECT sourceTable.child, sourceTable.parent direct_parent
		--	The top_parent from the previous iteration's set is pulled
		--		to maintain the categories throughout the iterations
		,recursiveSet.top_parent top_parent
	FROM #TempCustom1ParentChild sourceTable
	--	Recursively join the prior iteration of the set where the
	--		child from the previous set matches the parent of
	--		the joined-again source table
	INNER JOIN baseMembers recursiveSet
		ON recursiveSet.child=sourceTable.parent
)
--	Select out the numbers and category code for each BU/Dept
SELECT LEFT(child,4) bu_number, RIGHT(child,4) dept_number, top_parent category_code
INTO #TempCategories FROM baseMembers
WHERE LEN(child)=9 AND ISNUMERIC(LEFT(child,4)+RIGHT(child,4))=1


--	pull together division data into one final temp table
SELECT td.bu_number, td.dept_number, tdn.division_name
	,tmn.metric_name, pl.category_code
INTO #TempDivisionsFinal FROM #TempDivisions td
LEFT JOIN #TempDivisionNames tdn ON tdn.division_code=td.division_code
LEFT JOIN #TempMetrics tm ON tm.bu_number=td.bu_number AND tm.dept_number=td.dept_number
LEFT JOIN #TempMetricNames tmn ON tmn.metric_code=tm.metric_code
LEFT JOIN (	--	fill in GA HFM member with an & to match BudgetDB
	SELECT CASE WHEN LEN(category_code)=2 THEN LEFT(category_code,1) + '&' 
		+ RIGHT(category_code,1) ELSE category_code END category_code
		,bu_number, dept_number
	FROM #TempCategories
) tc ON tc.bu_number=td.bu_number AND tc.dept_number=td.dept_number
LEFT JOIN BudgetDB.dbo.pl_categories pl ON pl.category_code=tc.category_code


--	BU rollup (historical BU mapping to active BUs)
SELECT label historical_code, parentlabel active_bu_number
INTO #TempHistoricalBUs
FROM HFM_ActualsDB.dbo.PROD_CUSTOM1
WHERE parentlabel IN (
	SELECT label FROM HFM_ActualsDB.dbo.PROD_CUSTOM1
	WHERE ParentLabel='BU_DIV_DEPT'
) AND LEFT(label,5)+RIGHT(label,3)='HIST_BU'

; WITH baseMembers AS (
	--	ANCHOR MEMBER DEFINITION
	--		Starting with the hierarchy table, filter down
	--		to records where the Parent exists in the
	--		desired final parent list (category)
	SELECT sourceTable.child, sourceTable.parent direct_parent
		,sourceTable.parent top_parent, finalList.active_bu_number
	FROM #TempCustom1ParentChild sourceTable
	JOIN #TempHistoricalBUs finalList
		ON finalList.historical_code=sourceTable.parent
	UNION ALL
	--	RECURSIVE MEMBER DEFINITION
	--		Start, again, with the same hierarchy source table, unfiltered
	SELECT sourceTable.child, sourceTable.parent direct_parent
		--	The top_parent from the previous iteration's set is pulled
		--		to maintain the categories throughout the iterations
		,recursiveSet.top_parent top_parent, recursiveSet.active_bu_number
	FROM #TempCustom1ParentChild sourceTable
	--	Recursively join the prior iteration of the set where the
	--		child from the previous set matches the parent of
	--		the joined-again source table
	INNER JOIN baseMembers recursiveSet
		ON recursiveSet.child=sourceTable.parent
)
SELECT bm.child historical_bu_code, bm.active_bu_number, c1.[description] hfm_bu_description
INTO #TempHistoricalBUMapping
FROM baseMembers bm
LEFT JOIN (
	SELECT DISTINCT label, [description]
	FROM HFM_ActualsDB.dbo.PROD_CUSTOM1
) c1 ON c1.label=bm.child



--	clear temp table for tracking row counts
DELETE FROM #Temp

--	merge with permanent tables
--	business units
MERGE BudgetDB.dbo.business_units bu
USING (
	SELECT bu_number, bu_name, bu_number active_bu_number
	FROM #TempActiveBUs
	UNION
	SELECT historical_bu_code bu_number, hfm_bu_description bu_name, active_bu_number
	FROM #TempHistoricalBUMapping
) tb ON tb.bu_number=bu.bu_number
WHEN MATCHED THEN
	UPDATE SET bu.hfm_bu_description=tb.bu_name
		,bu.hist_to_current_bu_mapping=tb.active_bu_number
WHEN NOT MATCHED THEN
	INSERT (bu_number, bu_name, active_forecast_option
	,hfm_bu_description, hist_to_current_bu_mapping)
	VALUES (tb.bu_number, NULL, 0, tb.bu_name, tb.active_bu_number)
OUTPUT $action INTO #Temp;

--	add to trigger_log
INSERT INTO HFM_ActualsDB.dbo.trigger_log (trigger_name, trigger_run_date, table_name
	,rows_inserted, rows_updated, rows_deleted)
VALUES ('tr_hfm_custom1', @triggerFireDate, 'BudgetDB.dbo.business_units'
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='INSERT')
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='UPDATE'), 0)

DELETE FROM #Temp


--	departments table merge
MERGE BudgetDB.dbo.departments dp
USING (
	SELECT * FROM (SELECT dept_number, dept_name
		,ROW_NUMBER() OVER (PARTITION BY dept_number 
		ORDER BY dept_name ASC) RN
	FROM #TempDepartments
	) a WHERE RN=1
) td
ON td.dept_number=dp.dept_number
WHEN MATCHED THEN
	UPDATE SET dp.hfm_dept_description=td.dept_name
WHEN NOT MATCHED THEN
	INSERT (dept_number, dept_name, active_forecast_option, hfm_dept_description)
	VALUES (td.dept_number, NULL, 0, td.dept_name)
OUTPUT $action INTO #Temp;

--	add to trigger_log
INSERT INTO HFM_ActualsDB.dbo.trigger_log (trigger_name, trigger_run_date, table_name
	,rows_inserted, rows_updated, rows_deleted)
VALUES ('tr_hfm_custom1', @triggerFireDate, 'BudgetDB.dbo.departments'
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='INSERT')
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='UPDATE'), 0)
;

DELETE FROM #Temp


--	divisions table
MERGE BudgetDB.dbo.divisions dv
USING (
	SELECT * FROM (
	SELECT dept_number, bu_number, division_name, category_code, metric_name
		,ROW_NUMBER() OVER (PARTITION BY dept_number, bu_number
			ORDER BY division_name ASC) RN
	FROM #TempDivisionsFinal) a WHERE RN=1
) td
ON td.dept_number=dv.dept_number AND td.bu_number=dv.bu_number
WHEN NOT MATCHED THEN
	INSERT (dept_number, bu_number, division_name, category_code, metric)
	VALUES (td.dept_number, td.bu_number, td.division_name, td.category_code, td.metric_name)
OUTPUT $action INTO #Temp;

--	add to trigger_log
INSERT INTO HFM_ActualsDB.dbo.trigger_log (trigger_name, trigger_run_date, table_name
	,rows_inserted, rows_updated, rows_deleted)
VALUES ('tr_hfm_custom1', @triggerFireDate, 'BudgetDB.dbo.divisions'
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='INSERT')
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='UPDATE'), 0)
;

DELETE FROM #Temp


--	drop temp tables
IF OBJECT_ID('tempdb..#TempCustom1ParentChild') IS NOT NULL DROP TABLE #TempCustom1ParentChild
IF OBJECT_ID('tempdb..#TempBUs') IS NOT NULL DROP TABLE #TempBUs
IF OBJECT_ID('tempdb..#TempDepartments') IS NOT NULL DROP TABLE #TempDepartments
IF OBJECT_ID('tempdb..#TempDivisionNames') IS NOT NULL DROP TABLE #TempDivisionNames
IF OBJECT_ID('tempdb..#TempDivisions') IS NOT NULL DROP TABLE #TempDivisions
IF OBJECT_ID('tempdb..#TempActiveBUs') IS NOT NULL DROP TABLE #TempActiveBUs
IF OBJECT_ID('tempdb..#TempMetricNames') IS NOT NULL DROP TABLE #TempMetricNames
IF OBJECT_ID('tempdb..#TempMetrics') IS NOT NULL DROP TABLE #TempMetrics
IF OBJECT_ID('tempdb..#TempCategoryNames') IS NOT NULL DROP TABLE #TempCategoryNames
IF OBJECT_ID('tempdb..#TempCategories') IS NOT NULL DROP TABLE #TempCategories
IF OBJECT_ID('tempdb..#TempDivisionsFinal') IS NOT NULL DROP TABLE #TempDivisionsFinal
IF OBJECT_ID('tempdb..#TempHistoricalBUs') IS NOT NULL DROP TABLE #TempHistoricalBUs
IF OBJECT_ID('tempdb..#TempHistoricalBUMapping') IS NOT NULL DROP TABLE #TempHistoricalBUMapping
COMMIT TRANSACTION
END TRY


BEGIN CATCH
--	rollback transaction
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
--	insert error thrown into the trigger_error_log
INSERT INTO HFM_ActualsDB.dbo.trigger_error_log (trigger_name, trigger_run_date, error_message)
VALUES ('tr_hfm_custom1', @triggerFireDate,ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2)))
END CATCH




---------------------------------------------------------------
SET @triggerFireDate = GETDATE()
--	error handling with TRY..CATCH
BEGIN TRY
BEGIN TRANSACTION
--	Fill teams table with data from HFM Extended Analytics dump
--		create temp table to map out account hierarchy
SELECT label child, [description] child_name, parentlabel parent, isleaf
INTO #TempTeamHierarchy
FROM HFM_ActualsDB.dbo.PROD_CUSTOM2

--	run recursive query to find all members below the starting-level members
; WITH relevantMembers AS (
	--	ANCHOR MEMBER DEFINITION
	SELECT child, child_name, isleaf, parent direct_parent, parent top_parent
	FROM #TempTeamHierarchy
	WHERE parent = 'SEGMENT'
	UNION ALL
	--	RECURSIVE MEMBER DEFINITION
	SELECT sourceTable.child, sourceTable.child_name, sourceTable.isleaf, sourceTable.parent direct_parent
		,recursiveSet.top_parent top_parent
	FROM #TempTeamHierarchy sourceTable
	INNER JOIN relevantMembers recursiveSet
		ON recursiveSet.child=sourceTable.parent
)
SELECT child hfm_team_code, child_name team_name, isleaf
INTO #TempTeams FROM relevantMembers
WHERE isleaf=1

--	create table to track record counts
DELETE FROM #Temp

--	merge with Teams table
MERGE BudgetDB.dbo.teams tm
USING #TempTeams tt
ON tt.hfm_team_code=tm.hfm_team_code
WHEN MATCHED THEN
	UPDATE SET tm.hfm_team_description=tt.team_name, tm.hfm_leaf=tt.isleaf
WHEN NOT MATCHED THEN
	INSERT (hfm_team_code, hfm_team_description, hfm_leaf)
	VALUES (tt.hfm_team_code, tt.team_name, tt.isleaf)
OUTPUT $action INTO #Temp;

--	add to trigger_log
INSERT INTO HFM_ActualsDB.dbo.trigger_log (trigger_name, trigger_run_date, table_name
	,rows_inserted, rows_updated, rows_deleted)
VALUES ('tr_hfm_custom2', @triggerFireDate, 'BudgetDB.dbo.teams'
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='INSERT')
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='UPDATE'), 0)

IF OBJECT_ID('tempdb..#TempTeamHierarchy') IS NOT NULL DROP TABLE #TempTeamHierarchy
IF OBJECT_ID('tempdb..#TempTeams') IS NOT NULL DROP TABLE #TempTeams

COMMIT TRANSACTION
END TRY


BEGIN CATCH
--	rollback transaction
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
--	insert error thrown into the trigger_error_log
INSERT INTO HFM_ActualsDB.dbo.trigger_error_log (trigger_name, trigger_run_date, error_message)
VALUES ('tr_hfm_custom2', @triggerFireDate,ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2)))
END CATCH




---------------------------------------------------------------
SET @triggerFireDate = GETDATE()
--	error handling with TRY..CATCH
BEGIN TRY
BEGIN TRANSACTION

--	create temp table to map out account hierarchy
SELECT label child, [description] child_name, parentlabel parent, isleaf
INTO #TempProductHierarchy
FROM HFM_ActualsDB.dbo.PROD_CUSTOM3

--	run recursive query to find all members below the starting-level members
; WITH relevantMembers AS (
	--	ANCHOR MEMBER DEFINITION
	SELECT sourceTable.child, sourceTable.child_name, sourceTable.isleaf, sourceTable.parent direct_parent
		,sourceTable.parent top_parent
	FROM #TempProductHierarchy sourceTable
	WHERE parent IN ('PROD_DED','PROD_CLD')
	
	UNION ALL
	
	--	RECURSIVE MEMBER DEFINITION
	SELECT sourceTable.child, sourceTable.child_name, sourceTable.isleaf, sourceTable.parent direct_parent
		,recursiveSet.top_parent top_parent
	FROM #TempProductHierarchy sourceTable
	INNER JOIN relevantMembers recursiveSet
		ON recursiveSet.child=sourceTable.parent
)
SELECT child hfm_product_code, child_name product_name, isleaf, top_parent
INTO #TempProducts FROM relevantMembers
WHERE isleaf=1

--	create temp table for tracking record count
DELETE FROM #Temp

--	merge with products table
MERGE BudgetDB.dbo.products pd
USING #TempProducts tp
ON tp.hfm_product_code=pd.hfm_product_code
WHEN MATCHED THEN
	UPDATE SET pd.hfm_product_description=tp.product_name, pd.hfm_leaf=tp.isleaf
		,pd.product_type_code=tp.top_parent
WHEN NOT MATCHED THEN
	INSERT (hfm_product_code, hfm_product_description, hfm_leaf, product_type_code)
	VALUES (tp.hfm_product_code, tp.product_name, tp.isleaf, tp.top_parent)
OUTPUT $action INTO #Temp;

--	add to trigger_log
INSERT INTO HFM_ActualsDB.dbo.trigger_log (trigger_name, trigger_run_date, table_name
	,rows_inserted, rows_updated, rows_deleted)
VALUES ('tr_hfm_custom3', @triggerFireDate, 'BudgetDB.dbo.products'
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='INSERT')
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='UPDATE'), 0)

IF OBJECT_ID('tempdb..#TempProductHierarchy') IS NOT NULL DROP TABLE #TempProductHierarchy
IF OBJECT_ID('tempdb..#TempProducts') IS NOT NULL DROP TABLE #TempProducts
COMMIT TRANSACTION
END TRY


BEGIN CATCH
--	rollback transaction
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
--	insert error thrown into the trigger_error_log
INSERT INTO HFM_ActualsDB.dbo.trigger_error_log (trigger_name, trigger_run_date, error_message)
VALUES ('tr_hfm_custom3', @triggerFireDate,ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2)))
END CATCH




---------------------------------------------------------------
SET @triggerFireDate = GETDATE()
--	error handling with TRY..CATCH
BEGIN TRY
BEGIN TRANSACTION

--	Fill pl_items table with data from HFM Extended Analytics dump
--		create temp table to map out account hierarchy
SELECT label child, [description] child_name, parentlabel parent, isleaf
INTO #TempAccountHierarchy
FROM HFM_ActualsDB.dbo.PROD_ACCOUNT

--	run recursive query to find all members below the starting-level members
; WITH relevantMembers AS (
	--	ANCHOR MEMBER DEFINITION
	SELECT sourceTable.child, sourceTable.child_name, sourceTable.isleaf, sourceTable.parent direct_parent
		,sourceTable.parent top_parent
	FROM #TempAccountHierarchy sourceTable
	--	use BudgetDB table to define which parents to begin with
	JOIN BudgetDB.dbo.hfm_top_accounts finalList
		ON finalList.account_code=sourceTable.parent
	UNION ALL
	--	RECURSIVE MEMBER DEFINITION
	SELECT sourceTable.child, sourceTable.child_name, sourceTable.isleaf, sourceTable.parent direct_parent
		,recursiveSet.top_parent top_parent
	FROM #TempAccountHierarchy sourceTable
	INNER JOIN relevantMembers recursiveSet
		ON recursiveSet.child=sourceTable.parent
)
SELECT child hfm_account_code, child_name pl_name, isleaf
INTO #TempAccounts
FROM relevantMembers

--	create temp table to track record count
DELETE FROM #Temp

--	merge with pl_items table
MERGE BudgetDB.dbo.pl_items pl
USING #TempAccounts ta
ON ta.hfm_account_code=pl.hfm_account_code
WHEN MATCHED THEN
	UPDATE SET pl.hfm_account_description=ta.pl_name, pl.hfm_leaf=ta.isleaf
WHEN NOT MATCHED THEN
	INSERT (hfm_account_code, hfm_account_description, hfm_leaf)
	VALUES (ta.hfm_account_code, ta.pl_name, ta.isleaf)
OUTPUT $action INTO #Temp;

--	add to trigger_log
INSERT INTO HFM_ActualsDB.dbo.trigger_log (trigger_name, trigger_run_date, table_name
	,rows_inserted, rows_updated, rows_deleted)
VALUES ('tr_hfm_account', @triggerFireDate, 'BudgetDB.dbo.pl_items'
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='INSERT')
	,(SELECT COUNT(*) FROM #Temp WHERE action_taken='UPDATE'), 0)

--	drop temp tables
IF OBJECT_ID('tempdb..#TempAccountHierarchy') IS NOT NULL DROP TABLE #TempAccountHierarchy
IF OBJECT_ID('tempdb..#TempAccounts') IS NOT NULL DROP TABLE #TempAccounts
COMMIT TRANSACTION
END TRY


BEGIN CATCH
--	rollback transaction
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
--	insert error thrown into the trigger_error_log
INSERT INTO HFM_ActualsDB.dbo.trigger_error_log (trigger_name, trigger_run_date, error_message)
VALUES ('tr_hfm_account', @triggerFireDate,ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2)))
END CATCH




------------------------------------------------------------
--	dynamic SQL to transpose Actuals data
------------------------------------------------------------
--	error handling with TRY..CATCH
BEGIN TRY
BEGIN TRANSACTION

--	declare working variables
DECLARE @yr NVARCHAR(MAX)
	,@yrInt INT
	,@fullSQL NVARCHAR(MAX)

--	extract distinct years from HFM data dump
DECLARE hfm_year_cursor CURSOR LOCAL FOR
SELECT DISTINCT yr.label hfm_year
FROM HFM_ActualsDB.dbo.PROD_FACT f
LEFT JOIN HFM_ActualsDB.dbo.PROD_YEAR yr
ON yr.ID=f.yearid


--	loop through years and run dynamic sql to merge with actuals tables
OPEN hfm_year_cursor
FETCH NEXT FROM hfm_year_cursor INTO @yr

WHILE @@FETCH_STATUS = 0
BEGIN
	--	create actuals table if needed
	SET @yrInt = CAST(@yr AS INT)
	EXEC HFM_ActualsDB.dbo.create_actuals_table @yrInt
	
	--	build sql query
	SET @fullSQL = '
IF OBJECT_ID(''tempdb..#TempActuals'') IS NOT NULL DROP TABLE #TempActuals
IF OBJECT_ID(''tempdb..#Temp'') IS NOT NULL DROP TABLE #Temp

CREATE TABLE #Temp ( action_taken NVARCHAR(50) )

SELECT [Company], [Location], [Account], [Business Unit], [Department], [Team], [Product]
,currency_code
,ISNULL([Month 1],0) [Month 1], ISNULL([Month 2],0) [Month 2], ISNULL([Month 3],0) [Month 3]
,ISNULL([Month 4],0) [Month 4], ISNULL([Month 5],0) [Month 5], ISNULL([Month 6],0) [Month 6]
,ISNULL([Month 7],0) [Month 7], ISNULL([Month 8],0) [Month 8], ISNULL([Month 9],0) [Month 9]
,ISNULL([Month 10],0) [Month 10], ISNULL([Month 11],0) [Month 11], ISNULL([Month 12],0) [Month 12]
INTO #TempActuals FROM (
SELECT ''Month ''  + CAST(MONTH(CAST(CAST(pr.label AS NVARCHAR) + '' 1, '' 
		+ CAST(yr.label AS NVARCHAR) AS DATE)) AS NVARCHAR) [month_x]
	,LEFT(en.label,3) [Company] ,RIGHT(en.label,3) [Location]
	,ac.label [Account] ,CASE WHEN bu.hist_to_current_bu_mapping IS NULL
		THEN LEFT(c1.label,4) ELSE c1.label END [Business Unit]
	,CASE WHEN bu.hist_to_current_bu_mapping IS NULL THEN RIGHT(c1.label,4)
		ELSE ''0000'' END [Department] ,c2.label [Team] ,c3.label [Product]
	,vl.label currency_code, [dData] [Amount]
FROM HFM_ActualsDB.dbo.PROD_FACT f
LEFT JOIN HFM_ActualsDB.dbo.PROD_SCENARIO sn ON sn.ID=f.ScenarioID
LEFT JOIN ( SELECT DISTINCT ID, label
	FROM HFM_ActualsDB.dbo.PROD_YEAR
) yr ON yr.ID=f.YearID
LEFT JOIN ( SELECT DISTINCT ID, label
	FROM HFM_ActualsDB.dbo.PROD_PERIOD
) pr ON pr.ID=f.PeriodID
LEFT JOIN ( SELECT DISTINCT ID, label
	FROM HFM_ActualsDB.dbo.PROD_VIEW
) vw ON vw.ID=f.ViewID
LEFT JOIN ( SELECT DISTINCT ID, label
	FROM HFM_ActualsDB.dbo.PROD_ENTITY
) en ON en.ID=f.EntityID
LEFT JOIN ( SELECT DISTINCT ID, label
	FROM HFM_ActualsDB.dbo.PROD_VALUE
) vl ON vl.ID=f.ValueID
LEFT JOIN ( SELECT DISTINCT ID, label
	FROM HFM_ActualsDB.dbo.PROD_ACCOUNT
) ac ON ac.ID=f.AccountID
LEFT JOIN ( SELECT DISTINCT ID, label
	FROM HFM_ActualsDB.dbo.PROD_ICP
) icp ON icp.ID=f.ICPID
LEFT JOIN ( SELECT DISTINCT ID, label
	FROM HFM_ActualsDB.dbo.PROD_CUSTOM1
) c1 ON c1.ID=f.Custom1ID
LEFT JOIN ( SELECT DISTINCT ID, label
	FROM HFM_ActualsDB.dbo.PROD_CUSTOM2
) c2 ON c2.ID=f.Custom2ID
LEFT JOIN ( SELECT DISTINCT ID, label
	FROM HFM_ActualsDB.dbo.PROD_CUSTOM3
) c3 ON c3.ID=f.Custom3ID
LEFT JOIN ( SELECT DISTINCT ID, label
	FROM HFM_ActualsDB.dbo.PROD_CUSTOM4
) c4 ON c4.ID=f.Custom4ID
LEFT JOIN BudgetDB.dbo.business_units bu ON bu.bu_number=c1.label
WHERE vw.label=''Periodic'' AND yr.label=''' + @yr + '''
AND vl.label<>''[None]'' AND sn.label=''ACTUAL''
) AS p PIVOT (
SUM([Amount]) FOR month_x IN ([Month 1], [Month 2], [Month 3], [Month 4], [Month 5]
,[Month 6], [Month 7], [Month 8], [Month 9], [Month 10], [Month 11], [Month 12])
) AS pvt

MERGE HFM_ActualsDB.dbo.actuals_' + @yr + ' a USING #TempActuals ta
ON ta.[Company]=a.company_number AND ta.[Location]=a.location_number AND ta.[Account]=a.hfm_account_code
AND ta.[Business Unit]=a.bu_number AND ta.[Department]=a.dept_number AND ta.[Team]=a.hfm_team_code
AND ta.[Product]=a.hfm_product_code AND ta.currency_code=a.currency_code
WHEN NOT MATCHED BY SOURCE THEN		DELETE
WHEN NOT MATCHED BY TARGET THEN
INSERT (company_number, location_number, hfm_account_code, bu_number, dept_number
,hfm_team_code, hfm_product_code, currency_code, [Month 1], [Month 2], [Month 3], [Month 4], [Month 5], [Month 6]
,[Month 7], [Month 8], [Month 9], [Month 10], [Month 11], [Month 12])
VALUES (ta.[Company], ta.[Location], ta.[Account], ta.[Business Unit], ta.[Department]
	,ta.[Team], ta.[Product], ta.currency_code,ta.[Month 1], ta.[Month 2], ta.[Month 3]
	,ta.[Month 4], ta.[Month 5], ta.[Month 6], ta.[Month 7], ta.[Month 8], ta.[Month 9]
	,ta.[Month 10], ta.[Month 11], ta.[Month 12])
WHEN MATCHED THEN
UPDATE SET a.[Month 1]=ta.[Month 1], a.[Month 2]=ta.[Month 2], a.[Month 3]=ta.[Month 3]
	,a.[Month 4]=ta.[Month 4], a.[Month 5]=ta.[Month 5], a.[Month 6]=ta.[Month 6]
	,a.[Month 7]=ta.[Month 7], a.[Month 8]=ta.[Month 8], a.[Month 9]=ta.[Month 9]
	,a.[Month 10]=ta.[Month 10], a.[Month 11]=ta.[Month 11], a.[Month 12]=ta.[Month 12]
OUTPUT $action INTO #Temp;

INSERT INTO HFM_ActualsDB.dbo.trigger_log (trigger_name, trigger_run_date, table_name
,rows_inserted, rows_updated, rows_deleted)
VALUES (''tr_hfm_fact'', GETDATE(), ''HFM_ActualsDB.dbo.actuals_' + @yr + '''
,(SELECT COUNT(*) FROM #Temp WHERE action_taken=''INSERT'')
,(SELECT COUNT(*) FROM #Temp WHERE action_taken=''UPDATE'')
,(SELECT COUNT(*) FROM #Temp WHERE action_taken=''DELETE''))

DELETE FROM #Temp
'
	
	--	execute sql statement and move to next year
	EXEC sp_executesql @fullSQL
	FETCH NEXT FROM hfm_year_cursor INTO @yr
END

--	close cursor
CLOSE hfm_year_cursor
DEALLOCATE hfm_year_cursor

--	merge currency rates from HFM into BudgetDB
SELECT bsn.scenario_id, CAST(pd.label + ' 1, ' + yr.label AS DATE) conversion_month
	,ac.label conversion_type, c1.label from_currency, c2.label to_currency, f.dData conversion_rate
INTO #TempCurrency 
FROM HFM_ActualsDB.dbo.PROD_FACT f
LEFT JOIN HFM_ActualsDB.dbo.PROD_SCENARIO sn ON sn.id=f.scenarioid
LEFT JOIN HFM_ActualsDB.dbo.PROD_YEAR yr ON yr.id=f.yearid
LEFT JOIN HFM_ActualsDB.dbo.PROD_PERIOD pd ON pd.id=f.periodid
LEFT JOIN HFM_ActualsDB.dbo.PROD_ACCOUNT ac ON ac.id=f.accountid
LEFT JOIN HFM_ActualsDB.dbo.PROD_CUSTOM1 c1 ON c1.id=f.custom1id
LEFT JOIN HFM_ActualsDB.dbo.PROD_CUSTOM2 c2 ON c2.id=f.custom2id
LEFT JOIN BudgetDB.dbo.scenarios bsn ON bsn.scenario_name='Actual'
WHERE ac.parentlabel='EXCHANGE_RATES' AND sn.label='ACTUAL'

--	create temp table
CREATE TABLE #TempCount ( action_taken NVARCHAR(50) )


MERGE BudgetDB.dbo.currency_rates cr
USING #TempCurrency tc
ON tc.scenario_id=cr.scenario_id AND tc.conversion_month=cr.conversion_month
AND tc.conversion_type=cr.conversion_type AND tc.from_currency=cr.from_currency
AND tc.to_currency=cr.to_currency
WHEN NOT MATCHED THEN
	INSERT (scenario_id, conversion_month, conversion_type, from_currency
		,to_currency, conversion_rate)
	VALUES (tc.scenario_id, tc.conversion_month, tc.conversion_type
		,tc.from_currency, tc.to_currency, tc.conversion_rate)
WHEN MATCHED THEN
	UPDATE SET cr.conversion_rate=tc.conversion_rate
OUTPUT $action INTO #TempCount;

--	add to trigger_log table
INSERT INTO HFM_ActualsDB.dbo.trigger_log (trigger_name, trigger_run_date, table_name
	,rows_inserted, rows_updated, rows_deleted)
VALUES ('tr_hfm_fact', GETDATE(), 'BudgetDB.dbo.currency_rates'
	,(SELECT COUNT(*) FROM #TempCount WHERE action_taken='INSERT')
	,(SELECT COUNT(*) FROM #TempCount WHERE action_taken='UPDATE')
	,(SELECT COUNT(*) FROM #TempCount WHERE action_taken='DELETE'))

IF OBJECT_ID('tempdb..#TempCurrency') IS NOT NULL DROP TABLE #TempCurrency
COMMIT TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

END TRY

BEGIN CATCH
--	rollback transaction
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

--	insert error thrown into the trigger_error_log
INSERT INTO HFM_ActualsDB.dbo.trigger_error_log (trigger_name, trigger_run_date, error_message)
VALUES ('tr_hfm_fact', GETDATE(),ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2)))
END CATCH


GO
