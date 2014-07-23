USE BudgetDB
GO

IF OBJECT_ID('dbo.options_expense_items', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_expense_items
GO


CREATE PROCEDURE dbo.options_expense_items
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Expense P&L items.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

SELECT DISTINCT pl_item exp_item
	,CASE WHEN category_code IS NULL
	THEN 'FALSE' ELSE 'TRUE' END multi_item
FROM BudgetDB.dbo.pl_items
--	include only pl_items that are not
--		revenue items
WHERE rollup_to_hosting_revenue IS NULL
--	include only pl_items that have an Expense name
AND pl_item IS NOT NULL

GO
