USE BudgetDB
GO

IF OBJECT_ID('dbo.workbook_teams', 'U') IS NOT NULL
	DROP TABLE dbo.workbook_teams
GO


CREATE TABLE dbo.workbook_teams (
	workbook_id INT NOT NULL,
	hfm_team_code NVARCHAR(100) NULL
		CONSTRAINT fk_workbook_teams_hfm_team_code FOREIGN KEY
		REFERENCES dbo.teams (hfm_team_code)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_workbook_teams
ON dbo.workbook_teams (workbook_id, hfm_team_code)
WHERE (hfm_team_code IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Defines which Teams are set to be
			included for which workbooks. This mapping
			restricts what data is viewed in a workbook''s
			P&L as well as restricts what Teams
			forecasting workbooks are allowed to upload.
			NULLs are used to include all Teams.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'workbook_teams';
