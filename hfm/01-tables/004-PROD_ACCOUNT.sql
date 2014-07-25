USE HFM_ActualsDB
GO

IF OBJECT_ID('dbo.PROD_ACCOUNT', 'U') IS NOT NULL
	DROP TABLE dbo.PROD_ACCOUNT
GO


CREATE TABLE dbo.PROD_ACCOUNT (
	[ID] INT NOT NULL,
	[Label] NVARCHAR(100) NOT NULL,
	[ParentID] INT NOT NULL,
	[ParentLabel] NVARCHAR(100) NULL,
	[Description] NVARCHAR(256) NULL,
	[UserDefined1] NVARCHAR(256) NULL,
	[UserDefined2] NVARCHAR(256) NULL,
	[UserDefined3] NVARCHAR(256) NULL,
	[IsShared] INT NOT NULL,
	[IsCalculated] INT NOT NULL,
	[IsConsolidated] INT NOT NULL,
	[IsICP] INT NOT NULL,
	[AccountType] NVARCHAR(256) NOT NULL,
	[IsLeaf] INT NOT NULL,
	PRIMARY KEY CLUSTERED ([ID], [ParentID])
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			HFM table to maintain information
			about the ACCOUNT dimension. The
			primary key (ID, ParentID) maps
			out the hierarchy implemented in
			the dimension.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-25
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'PROD_ACCOUNT';
