USE BudgetDB
GO

IF OBJECT_ID('dbo.locations', 'U') IS NOT NULL
	DROP TABLE dbo.locations
GO


CREATE TABLE dbo.locations (
	location_number NCHAR(3) NOT NULL,
	location_name NVARCHAR(256) NULL,
	active_forecast_option BIT NOT NULL,
	real_location BIT NOT NULL,
	hfm_location_description NVARCHAR(256) NULL,
	us_0_intl_1 BIT NULL,
	CONSTRAINT pk_locations
		PRIMARY KEY CLUSTERED (location_number)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_locations_location_name
ON dbo.locations (location_name)
WHERE (location_name IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Core dimension table that maintains
			the list of all Locations and
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
	,@level1name = N'locations';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Directly maps to part of the HFM ENTITY dimension
			member values, which have the format XXX_XXX where
			the last 3 digits together are the Location number.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'locations'
	,@level2type = N'COLUMN'
	,@level2name = N'location_number';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Flag to determine whether the location number
			is a real location or a number used for
			Intercompany transaction purposes (constraint
			from structure in Oracle and HFM).
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'locations'
	,@level2type = N'COLUMN'
	,@level2name = N'real_location';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			DEPRECATED for dbo.locations
			Used to differentiate between US and
			International, i.e., whether the Location
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
	,@level1name = N'locations'
	,@level2type = N'COLUMN'
	,@level2name = N'us_0_intl_1';
