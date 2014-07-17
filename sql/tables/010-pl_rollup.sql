USE BudgetDB
GO

IF OBJECT_ID('dbo.pl_rollup', 'U') IS NOT NULL
	DROP TABLE dbo.pl_rollup
GO


CREATE TABLE dbo.pl_rollup (
	hfm_account_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_pl_rollup_hfm_account_code FOREIGN KEY  
		REFERENCES dbo.pl_items (hfm_account_code),
	hfm_account_rollup NVARCHAR(100) NOT NULL
		CONSTRAINT fk_pl_rollup_hfm_account_rollup FOREIGN KEY  
		REFERENCES dbo.pl_items (hfm_account_code),
	CONSTRAINT pk_pl_rollup
		PRIMARY KEY CLUSTERED (hfm_account_code, hfm_account_rollup)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Maps parent-child relationships, based on HFM
			Account dimension hierarchy, to be used
			to remap Actuals to a dbo.pl_items.pl_item that
			contains a value that maps to the P&L in Excel.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'pl_rollup';
