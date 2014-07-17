USE BudgetDB
GO

IF OBJECT_ID('dbo.business_units', 'U') IS NOT NULL
	DROP TABLE dbo.business_units
GO


CREATE TABLE dbo.business_units (
	bu_number NVARCHAR(100) NOT NULL,
	bu_name NVARCHAR(256) NULL,
	active_forecast_option BIT NOT NULL,
	us_0_intl_1 BIT NULL,
	hfm_bu_description NVARCHAR(256) NULL,
	hist_to_current_bu_mapping NVARCHAR(100) NULL
		CONSTRAINT fk_business_units_hist_to_current_bu_mapping FOREIGN KEY  
		REFERENCES dbo.business_units (bu_number),
	CONSTRAINT pk_business_units
		PRIMARY KEY CLUSTERED (bu_number)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_business_units_bu_name
ON dbo.business_units (bu_name)
WHERE (bu_name IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Core dimension table that maintains
			the list of all Business Units and
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
	,@level1name = N'business_units';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Directly maps to part of the HFM CUSTOM1 dimension
			member values, which have the format XXXX_XXXX where
			the first 4 digits together are the Business Unit number.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'business_units'
	,@level1type = N'COLUMN'
	,@level1name = N'bu_number';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			DEPRECATED for dbo.business_units
			Used to differentiate between US and
			International, i.e., whether the Business Unit
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
	,@level1name = N'business_units'
	,@level1type = N'COLUMN'
	,@level1name = N'us_0_intl_1';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Maps parent-child relationships, based on the
			HFM hierarchy for Business Units. Mainly needed
			to handle the historical Business Units and
			mapping them to where they currently roll into.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'business_units'
	,@level1type = N'COLUMN'
	,@level1name = N'hist_to_current_bu_mapping';
