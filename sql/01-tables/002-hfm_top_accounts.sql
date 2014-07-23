USE BudgetDB
GO

IF OBJECT_ID('dbo.hfm_top_accounts', 'U') IS NOT NULL
	DROP TABLE dbo.hfm_top_accounts
GO


CREATE TABLE dbo.hfm_top_accounts (
	account_code NVARCHAR(100) NOT NULL,
	CONSTRAINT pk_hfm_top_accounts 
		PRIMARY KEY (account_code)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Starting point for the HFM transpose procedure
			(HFM_ActualsDB.dbo.transpose_hfm_data) for identifying,
			through recursivley extracting all related leaf members,
			which accounts to transpose to update the actuals_*
			tables.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'hfm_top_accounts';
