USE HFM_ActualsDB
GO

IF OBJECT_ID('dbo.trigger_error_log', 'U') IS NOT NULL
	DROP TABLE dbo.trigger_error_log
GO


CREATE TABLE dbo.trigger_error_log (
	trigger_name NVARCHAR(128) NULL,
	trigger_run_date DATETIME2(7) NULL,
	error_message NVARCHAR(1024) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Log table to capture any
			errors thrown by the procedure
			used to transpose the data
			from HFM''s raw format into the
			format compatible with the
			budget system.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-25
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'trigger_error_log';
