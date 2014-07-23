USE BudgetDB
GO

IF OBJECT_ID('dbo.workbook_locations', 'U') IS NOT NULL
	DROP TABLE dbo.workbook_locations
GO


CREATE TABLE dbo.workbook_locations (
	workbook_id INT NOT NULL,
	location_number NCHAR(3) NULL
		CONSTRAINT fk_workbook_locations_location_number FOREIGN KEY
		REFERENCES dbo.locations (location_number)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_workbook_locations
ON dbo.workbook_locations (workbook_id, location_number)
WHERE (location_number IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Defines which Locations are set to be
			included for which workbooks. This mapping
			restricts what data is viewed in a workbook''s
			P&L as well as restricts what Locations
			forecasting workbooks are allowed to upload.
			NULLs are used to include all Locations.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'workbook_locations';
