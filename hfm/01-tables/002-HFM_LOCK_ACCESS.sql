USE HFM_ActualsDB
GO

IF OBJECT_ID('dbo.HFM_LOCK_ACCESS', 'U') IS NOT NULL
	DROP TABLE dbo.HFM_LOCK_ACCESS
GO


CREATE TABLE dbo.HFM_LOCK_ACCESS (
	[TaskID] INT IDENTITY(1,1) NOT NULL,
	[sServer] NVARCHAR(100) NOT NULL,
	[lThreadID] INT NOT NULL,
	[sKey1] NVARCHAR(100) NOT NULL,
	[sKey2] NVARCHAR(100) NOT NULL,
	[bWriteable] SMALLINT NOT NULL,
	[dTimestamp] FLOAT NOT NULL,
	PRIMARY KEY CLUSTERED ([TaskID] ASC)
	UNIQUE NONCLUSTERED 
		([sServer] ASC, [lThreadID] ASC,
		[sKey1] ASC, [sKey2] ASC)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Table HFM uses to keep track of when an
			Extended Analytics load is currently
			taking place.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-25
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'HFM_LOCK_ACCESS';
