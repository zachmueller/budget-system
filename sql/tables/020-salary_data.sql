USE BudgetDB
GO

IF OBJECT_ID('dbo.salary_data', 'U') IS NOT NULL
	DROP TABLE dbo.salary_data
GO


CREATE TABLE dbo.salary_data (
	employee_id NVARCHAR(256) NULL,
	last_name NVARCHAR(256) NULL,
	first_name NVARCHAR(256) NULL,
	job_code NVARCHAR(256) NULL,
	job_id INT NOT NULL
		CONSTRAINT fk_salary_data_job_id FOREIGN KEY  
		REFERENCES dbo.job_titles (job_id),
	manager NVARCHAR(256) NULL,
	ft_pt NVARCHAR(256) NULL,
	base DECIMAL(30, 16) NULL,
	bonus DECIMAL(30, 16) NULL,
	commission_target DECIMAL(30, 16) NULL,
	company_number NCHAR(3) NOT NULL
		CONSTRAINT fk_salary_data_company_number FOREIGN KEY  
		REFERENCES dbo.companies (company_number),
	location_number NCHAR(3) NOT NULL
		CONSTRAINT fk_salary_data_location_number FOREIGN KEY  
		REFERENCES dbo.locations (location_number),
	bu_number NVARCHAR(100) NOT NULL
		CONSTRAINT fk_salary_data_bu_number FOREIGN KEY  
		REFERENCES dbo.business_units (bu_number),
	dept_number NCHAR(4) NOT NULL
		CONSTRAINT fk_salary_data_dept_number FOREIGN KEY  
		REFERENCES dbo.departments (dept_number),
	hfm_team_code NVARCHAR(100) NOT NULL
		CONSTRAINT fk_salary_data_hfm_team_code FOREIGN KEY  
		REFERENCES dbo.teams (hfm_team_code),
	currency_code NCHAR(3) NULL
		CONSTRAINT fk_salary_data_currency_code FOREIGN KEY  
		REFERENCES dbo.currencies (currency_code)
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Data imported from the HR system to map
			each employee to their respective dimensions
			as well as basic salary-related data, used
			primarily for analytics. All non-admin users
			are restricted from SELECT access to this
			table to keep sensitive data private.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-17
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TABLE'
	,@level1name = N'salary_data';
