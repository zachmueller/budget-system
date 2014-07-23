USE BudgetDB
GO

IF OBJECT_ID('dbo.options_categories', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_categories
GO


CREATE PROCEDURE dbo.options_categories
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all Categories in the
			database.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

SELECT category_name
FROM BudgetDB.dbo.categories

GO
