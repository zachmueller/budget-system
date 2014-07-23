USE BudgetDB
GO

IF OBJECT_ID('dbo.options_gl_accounts', 'P') IS NOT NULL
	DROP PROCEDURE dbo.options_gl_accounts
GO


CREATE PROCEDURE dbo.options_gl_accounts
AS
/*
summary:	>
			Downloads a reference table into
			the Excel workbooks.
			This reference table provides a
			list of all GL Accounts and
			their account names.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

SET NOCOUNT ON

SELECT DISTINCT LEFT(Label,6) gl_account_number, [Description] gl_account_name
FROM HFM_ActualsDB.dbo.PROD_ACCOUNT
--	only include raw GL accounts, as HFM ACCOUNT dimension members
--		also include hierarchies the accounts roll up into
WHERE ISNUMERIC(LEFT(label,6))=1
--	only include GL accounts that are for Expenses or Revenue
AND LEFT(label,1) IN ('4','5')

GO
