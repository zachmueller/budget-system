USE BudgetDB
GO

IF OBJECT_ID('dbo.job_titles', 'U') IS NOT NULL
	DROP TABLE dbo.job_titles
GO


CREATE TABLE dbo.job_titles (
	job_id INT IDENTITY(1,1) NOT NULL,
	job_title NVARCHAR(256) NOT NULL,
	job_consolidation NVARCHAR(256) NULL,
	management_level NVARCHAR(256) NULL,
	CONSTRAINT pk_job_titles 
		PRIMARY KEY CLUSTERED (job_id),
	CONSTRAINT unq_job_titles_job_title 
		UNIQUE NONCLUSTERED (job_title)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Maintains list of job titles and some
			basic attributes about each.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'job_titles';
