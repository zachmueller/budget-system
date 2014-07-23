USE BudgetDB
GO

IF OBJECT_ID('dbo.workbook_companies', 'U') IS NOT NULL
	DROP TABLE dbo.workbook_companies
GO


CREATE TABLE dbo.workbook_companies (
	workbook_id INT NOT NULL,
	company_number NCHAR(3) NULL
		CONSTRAINT fk_workbook_companies_company_number FOREIGN KEY
		REFERENCES dbo.companies (company_number)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_workbook_companies
ON dbo.workbook_companies (workbook_id, company_number)
WHERE (company_number IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Defines which Companies are set to be
			included for which workbooks. This mapping
			restricts what data is viewed in a workbook''s
			P&L as well as restricts what Companies
			forecasting workbooks are allowed to upload.
			NULLs are used to include all Companies.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'workbook_companies';
