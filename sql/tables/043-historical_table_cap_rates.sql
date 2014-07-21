USE BudgetDB
GO

IF OBJECT_ID('dbo.historical_table_cap_rates', 'U') IS NOT NULL
	DROP TABLE dbo.historical_table_cap_rates
GO


CREATE TABLE dbo.historical_table_cap_rates (
	id BIGINT NOT NULL
		CONSTRAINT fk_historical_table_cap_rates_id FOREIGN KEY
		REFERENCES dbo.frozen_versions (id),
	[Month 1] DECIMAL(12, 8) NULL,
	[Month 2] DECIMAL(12, 8) NULL,
	[Month 3] DECIMAL(12, 8) NULL,
	[Month 4] DECIMAL(12, 8) NULL,
	[Month 5] DECIMAL(12, 8) NULL,
	[Month 6] DECIMAL(12, 8) NULL,
	[Month 7] DECIMAL(12, 8) NULL,
	[Month 8] DECIMAL(12, 8) NULL,
	[Month 9] DECIMAL(12, 8) NULL,
	[Month 10] DECIMAL(12, 8) NULL,
	[Month 11] DECIMAL(12, 8) NULL,
	[Month 12] DECIMAL(12, 8) NULL,
	[Month 13] DECIMAL(12, 8) NULL,
	[Month 14] DECIMAL(12, 8) NULL,
	[Month 15] DECIMAL(12, 8) NULL,
	[Month 16] DECIMAL(12, 8) NULL,
	[Month 17] DECIMAL(12, 8) NULL,
	[Month 18] DECIMAL(12, 8) NULL,
	[Month 19] DECIMAL(12, 8) NULL,
	[Month 20] DECIMAL(12, 8) NULL,
	[Month 21] DECIMAL(12, 8) NULL,
	[Month 22] DECIMAL(12, 8) NULL,
	[Month 23] DECIMAL(12, 8) NULL,
	[Month 24] DECIMAL(12, 8) NULL,
	[Month 25] DECIMAL(12, 8) NULL,
	[Month 26] DECIMAL(12, 8) NULL,
	[Month 27] DECIMAL(12, 8) NULL,
	[Month 28] DECIMAL(12, 8) NULL,
	[Month 29] DECIMAL(12, 8) NULL,
	[Month 30] DECIMAL(12, 8) NULL,
	[Month 31] DECIMAL(12, 8) NULL,
	[Month 32] DECIMAL(12, 8) NULL,
	[Month 33] DECIMAL(12, 8) NULL,
	[Month 34] DECIMAL(12, 8) NULL,
	[Month 35] DECIMAL(12, 8) NULL,
	[Month 36] DECIMAL(12, 8) NULL,
	created_by NVARCHAR(256) NULL,
	created_date DATETIME2(7) NULL,
	last_updated_by NVARCHAR(256) NULL,
	last_updated_date DATETIME2(7) NULL,
	CONSTRAINT pk_historical_table_cap_rates 
		PRIMARY KEY CLUSTERED (id)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Store capitalization rates per related headcount
			record for all frozen version scenarios.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'historical_table_cap_rates';


--------------------------------------------------------
EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Foreign key to dbo.frozen_versions to
			directly map the capitalization rates
			to their related records to which the
			rates are applied for calculating the
			capitalized portion of salaries.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-20
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'historical_table_cap_rates'
	,@level2type = N'COLUMN'
	,@level2name = N'id';
