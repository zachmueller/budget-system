USE BudgetDB
GO

IF OBJECT_ID('dbo.workbook_business_units', 'U') IS NOT NULL
	DROP TABLE dbo.workbook_business_units
GO


CREATE TABLE dbo.workbook_business_units (
	workbook_id INT NOT NULL,
	bu_number NVARCHAR(100) NULL
		CONSTRAINT fk_workbook_business_units_bu_number FOREIGN KEY
		REFERENCES dbo.business_units (bu_number)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_workbook_business_units
ON dbo.workbook_business_units (workbook_id, bu_number)
WHERE (bu_number IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Defines which Business Units are set to be
			included for which workbooks. This mapping
			restricts what data is viewed in a workbook''s
			P&L as well as restricts what Business Units
			forecasting workbooks are allowed to upload.
			NULLs are used to include all Business Units.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'workbook_business_units';
