USE BudgetDB
GO

IF OBJECT_ID('dbo.departments', 'U') IS NOT NULL
	DROP TABLE dbo.departments
GO


CREATE TABLE dbo.departments (
	dept_number NCHAR(4) NOT NULL,
	dept_name NVARCHAR(256) NULL,
	active_forecast_option BIT NOT NULL,
	us_0_intl_1 BIT NULL,
	hfm_dept_description NVARCHAR(256) NULL,
	CONSTRAINT pk_departments
		PRIMARY KEY CLUSTERED (dept_number)
)
GO


CREATE UNIQUE NONCLUSTERED INDEX unq_departments_dept_name
ON dbo.departments (dept_name)
WHERE (dept_name IS NOT NULL)
GO
