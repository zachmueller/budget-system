USE BudgetDB
GO

IF TYPE_ID('dbo.bulk_upload_salaries') IS NOT NULL
	DROP TYPE dbo.bulk_upload_salaries
GO


CREATE TYPE dbo.bulk_upload_salaries AS TABLE(
	employee_id NVARCHAR(256) NULL,
	last_name NVARCHAR(256) NULL,
	first_name NVARCHAR(256) NULL,
	job_code NVARCHAR(256) NULL,
	job_title NVARCHAR(256) NULL,
	manager NVARCHAR(256) NULL,
	ft_pt NVARCHAR(256) NULL,
	base DECIMAL(30, 16) NULL,
	bonus DECIMAL(30, 16) NULL,
	commission_target DECIMAL(30, 16) NULL,
	company_number NCHAR(3) NULL,
	location_number NCHAR(3) NULL,
	bu_number NVARCHAR(100) NULL,
	dept_number NCHAR(4) NULL,
	hfm_team_code NVARCHAR(100) NULL
)
GO


EXEC sys.sp_addextendedproperty @name = N'Documentation'
	,@value = N'
summary:	>
			Received data from the Master Assumptions workbook
			for all individual employees, to include information
			such as names, IDs, job titles, and salary data.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
'
	,@level0type = N'SCHEMA'
	,@level0name = N'dbo'
	,@level1type = N'TYPE'
	,@level1name = N'bulk_upload_salaries';
