USE BudgetDB
GO

IF OBJECT_ID('dbo.teams', 'U') IS NOT NULL
	DROP TABLE dbo.teams
GO


CREATE TABLE dbo.teams (
	hfm_team_code NVARCHAR(100) NOT NULL,
	team_name NVARCHAR(256) NULL,
	team_consolidation NVARCHAR(256) NULL,
	active_forecast_option BIT NOT NULL,
	us_0_intl_1 BIT NULL,
	hfm_team_description NVARCHAR(256) NULL,
	hfm_leaf BIT NULL,
	CONSTRAINT pk_teams
		PRIMARY KEY CLUSTERED (hfm_team_code)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_teams_team_name
ON dbo.teams (team_name)
WHERE (team_name IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Core dimension table that maintains
			the list of all Teams and
			their attributes.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'teams';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Directly maps to the HFM CUSTOM2 dimension
			member values, which have the format XXX where
			the 3 digits together are the Team number.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'teams'
	,@level2type = N'COLUMN'
	,@level2name = N'hfm_team_code';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Ported over from the old budget models.
			Used to simplify the workbook creation process
			as well as the filtering of the P&L as
			many teams may fall into a larger group
			of teams when viewed for budgeting purposes.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'teams'
	,@level2type = N'COLUMN'
	,@level2name = N'team_consolidation';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			DEPRECATED for dbo.teams
			Used to differentiate between US and
			International, i.e., whether the Team
			is valid for either US or International.
			NULL = Both
			0 = US
			1 = International
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'teams'
	,@level2type = N'COLUMN'
	,@level2name = N'us_0_intl_1';
