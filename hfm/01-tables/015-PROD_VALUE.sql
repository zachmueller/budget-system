USE HFM_ActualsDB
GO

IF OBJECT_ID('dbo.PROD_VALUE', 'U') IS NOT NULL
	DROP TABLE dbo.PROD_VALUE
GO


CREATE TABLE dbo.PROD_VALUE (
	[ID] [int] NOT NULL,
	[Label] [nvarchar](100) NOT NULL,
	[ParentID] [int] NOT NULL,
	[ParentLabel] [nvarchar](100) NULL,
	[Description] [nvarchar](256) NULL,
	[IsShared] [int] NOT NULL,
	[IsLeaf] [int] NOT NULL,
	PRIMARY KEY CLUSTERED ([ID], [ParentID])
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			HFM table to maintain information
			about the VALUE dimension. The
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
	,@level1name = N'PROD_VALUE';
