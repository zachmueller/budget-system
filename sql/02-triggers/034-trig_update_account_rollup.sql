USE BudgetDB
GO

IF OBJECT_ID('dbo.trig_update_account_rollup', 'TR') IS NOT NULL
	DROP TRIGGER dbo.trig_update_account_rollup
GO


CREATE TRIGGER dbo.trig_update_account_rollup
ON dbo.pl_items
AFTER INSERT, UPDATE
/*
summary:	>
			Refresh dbo.pl_rollup table based on any
			changes made to dbo.pl_items. Uses a recursive
			query to find which Forecast-used parent each
			individual hfm_account_code rolls up into.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-21
*/
AS

SET NOCOUNT ON

BEGIN TRANSACTION
SELECT hfm.label AS child, hfm.parentlabel AS parent, pl.active_forecast_option
INTO #TempParentChildHierarchy
FROM HFM_ActualsDB.dbo.PROD_ACCOUNT hfm
LEFT JOIN BudgetDB.dbo.pl_items pl
ON pl.hfm_account_code=hfm.label

SELECT hfm_account_code AS parent
INTO #TempForecastLevelMembers
FROM BudgetDB.dbo.pl_items
WHERE active_forecast_option=1

; WITH baseMembers AS (
	--	ANCHOR MEMBER DEFINITION
	--		Starting with the hierarchy table (defining parent-child
	--		relationships), filter down to records where the Parent
	--		exists in the desired final parent list
	SELECT sourceTable.child, sourceTable.parent direct_parent
		,sourceTable.parent top_parent, 0 AS level
	FROM #TempParentChildHierarchy sourceTable
	JOIN #TempForecastLevelMembers finalList
		ON finalList.parent=sourceTable.parent
	--	exclude any items that are set to active
	WHERE sourceTable.active_forecast_option=0
	UNION ALL
	--	RECURSIVE MEMBER DEFINITION
	--		Start, again, with the same hierarchy source table, unfiltered
	SELECT sourceTable.child, sourceTable.parent direct_parent
		--	The top_parent from the previous iteration's set is pulled
		--		to maintain the highest-level parent (that from the
		--		desired output list) throughout the iterations
		,recursiveSet.top_parent top_parent, level + 1 AS level
	FROM #TempParentChildHierarchy sourceTable
	--	Recusively join the prior iteration of the set where the
	--		child from the previous set matches the parent of
	--		the joined-again source table
	INNER JOIN baseMembers recursiveSet
		ON recursiveSet.child=sourceTable.parent
	--	recursively implement the exclusion
	WHERE sourceTable.active_forecast_option=0
)
--	Select out desired fields from the recursively filled set
SELECT bm.child, bm.direct_parent, bm.top_parent, bm.level
INTO #TempRollup
FROM baseMembers bm

--	delete old rollup
DELETE FROM BudgetDB.dbo.pl_rollup

--	insert new rollup
INSERT INTO BudgetDB.dbo.pl_rollup (hfm_account_code, hfm_account_rollup)
SELECT child, top_parent
FROM (
	--	when items show up at multiple levels of rolling up, only
	--		include the mapping closest to its rollup
	SELECT child, top_parent
		,ROW_NUMBER() OVER (PARTITION BY child ORDER BY level ASC) RN
	FROM #TempRollup
) a
WHERE a.RN=1
UNION
--	also include remaining members in the pl_items table
--		and assume they "rollup" to themselves
SELECT pl.hfm_account_code child, pl.hfm_account_code top_parent
FROM BudgetDB.dbo.pl_items pl
LEFT JOIN #TempRollup tr
ON tr.child=pl.hfm_account_code
WHERE tr.child IS NULL

COMMIT TRANSACTION

GO
