USE BudgetDB
GO

IF OBJECT_ID('dbo.workbook_departments', 'U') IS NOT NULL
	DROP TABLE dbo.workbook_departments
GO


CREATE TABLE dbo.workbook_departments (
	workbook_id INT NOT NULL,
	dept_number NCHAR(4) NULL
		CONSTRAINT fk_workbook_departments_dept_number FOREIGN KEY
		REFERENCES dbo.departments (dept_number)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_workbook_departments
ON dbo.workbook_departments (workbook_id, dept_number)
WHERE (dept_number IS NOT NULL)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Defines which Departments are set to be
			included for which workbooks. This mapping
			restricts what data is viewed in a workbook''s
			P&L as well as restricts what Departments
			forecasting workbooks are allowed to upload.
			NULLs are used to include all Departments.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'workbook_departments';
