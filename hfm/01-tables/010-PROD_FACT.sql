USE HFM_ActualsDB
GO

IF OBJECT_ID('dbo.PROD_FACT', 'U') IS NOT NULL
	DROP TABLE dbo.PROD_FACT
GO


CREATE TABLE dbo.PROD_FACT (
	[ScenarioID] INT NOT NULL,
	[YearID] INT NOT NULL,
	[PeriodID] INT NOT NULL,
	[ViewID] INT NOT NULL,
	[EntityID] INT NOT NULL,
	[ParentID] INT NOT NULL,
	[ValueID] INT NOT NULL,
	[AccountID] INT NOT NULL,
	[ICPID] INT NOT NULL,
	[Custom1ID] INT NOT NULL,
	[Custom2ID] INT NOT NULL,
	[Custom3ID] INT NOT NULL,
	[Custom4ID] INT NOT NULL,
	[dData] FLOAT NOT NULL,
	PRIMARY KEY CLUSTERED (
	[ScenarioID], [YearID], [PeriodID],
	[ViewID], [EntityID], [ParentID],
	[ValueID], [AccountID], [ICPID],
	[Custom1ID], [Custom2ID],
	[Custom3ID], [Custom4ID])
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			HFM FACT table that contains all
			individual pieces of data from the
			system, mapped to every dimension.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-25
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'PROD_FACT';
