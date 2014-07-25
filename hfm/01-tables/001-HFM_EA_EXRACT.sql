USE HFM_ActualsDB
GO

IF OBJECT_ID('dbo.HFM_EA_EXTRACT', 'U') IS NOT NULL
	DROP TABLE dbo.HFM_EA_EXTRACT
GO


CREATE TABLE dbo.HFM_EA_EXTRACT (
	[Prefix] NVARCHAR(10) NOT NULL,
	[AppName] NVARCHAR(10) NOT NULL,
	[Task] NVARCHAR(256) NULL,
	[Dimension] INT NOT NULL,
	[dTimestamp] FLOAT NOT NULL,
	UNIQUE NONCLUSTERED 
		([Prefix], [Dimension])
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Table HFM uses to log when each Extended Analytics
			load last took place.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-25
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'HFM_EA_EXTRACT';
