USE BudgetDB
GO

IF OBJECT_ID('dbo.options_currency_codes', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_currency_codes
GO


CREATE PROCEDURE dbo.options_currency_codes
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all currency code.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

SELECT currency_code
FROM BudgetDB.dbo.currencies

GO
