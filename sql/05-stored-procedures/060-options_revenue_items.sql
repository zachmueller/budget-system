USE BudgetDB
GO

IF OBJECT_ID('dbo.options_revenue_items', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_revenue_items
GO


CREATE PROCEDURE dbo.options_revenue_items
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Revenue P&L items.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

SELECT pl_item rev_item
	,CASE WHEN rollup_to_hosting_revenue=1 THEN 'TRUE'
	ELSE 'FALSE' END hosting_rev
FROM BudgetDB.dbo.pl_items
--	include only revenue pl_items
WHERE rollup_to_hosting_revenue IS NOT NULL

GO
