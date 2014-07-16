USE BudgetDB
GO

IF OBJECT_ID('dbo.fnOutputSelectPreMonths', 'FN') IS NOT NULL
	DROP FUNCTION dbo.fnOutputSelectPreMonths
GO


CREATE FUNCTION dbo.fnOutputSelectPreMonths(
	@wbID INT			--	workbook ID
	,@t NVARCHAR(15)	--	directly the table alias, indicates the run type. 
						--		determines whether to return NULLs for some fields
	,@a NVARCHAR(128)	--	specific "alias.field_name" to pull Account
)
RETURNS NVARCHAR(1024)
AS
/*
summary:	>
			Returns a SQL string to feed the primary calculation procedure
			that feeds both regular P&L refreshes as well as the
			dbo.create_frozen_versions procedure. This function
			returns the part of the SELECT statement that
			comes BEFORE the [Month X]'s fields.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
*/
BEGIN
	DECLARE @ret NVARCHAR(1024) = CHAR(13)+CHAR(10) + 'SELECT '
		,@j NVARCHAR(256) = 'NULL'		--	string for job_title field
		,@d NVARCHAR(256) = 'NULL'		--	string for [description] field
	
	--	if called by dbo.create_frozen_version (i.e., @wbID = -1),
	--		select out columns of raw (primary key) values
	IF ( @wbID < 0 )
	BEGIN
		--	if Live Forecast ('lf'), include Job ID and Description
		IF ( @t = 'lf' )
		BEGIN
			SET @ret = @ret + 'lf.company_number, lf.bu_number, lf.dept_number, lf.hfm_team_code, lf.hfm_product_code
	,lf.location_number, lf.job_id, ' + @a + ' hfm_account_code, lf.[description]'
		END
		ELSE
		--	if from SBC table, prefix all with "sbc" alias and hard-code hfm_product_code with default
		BEGIN
			SET @ret = @ret + @t + '.company_number, ' + @t + '.bu_number, ' + @t + '.dept_number
	,' + @t + '.hfm_team_code, ''0000_0000'' hfm_product_code
	,' + @t + '.location_number, NULL job_id, ' + @a + ', NULL [description]'
		END
	END
	ELSE
	BEGIN
		--	update values for job_title/[description] fields
		IF ( @t IN ('lf','fv') )
		BEGIN
			SET @j = 'jt.job_title'
			SET @d = @t + '.[description]'
		END
		
		SET @ret = @ret + 'sn.scenario_name [Scenario],dv.division_name [Division]
	,cp.company_name [Company],bu.bu_name [Business Unit],dp.dept_name [Department]
	,tm.team_name [Team],tm.team_consolidation [Team Consolidation],pd.product_name [Product],lc.location_name [Location]
	,' + @j + ' [Job Title]
	,CASE WHEN pl.rollup_to_hosting_revenue=1 THEN 
		CASE WHEN pd.product_type_code=''PROD_CLD'' THEN ''Cloud Hosting Revenue''
		ELSE pl.pl_item END
	ELSE
		CASE WHEN pl.category_code IS NULL THEN pl.pl_item
		ELSE pl.pl_item + '' - '' + pl.category_code END
	END [P&L Item], ' + @d + ' [Description]'
	END
	
	--	return final output
	RETURN @ret
END
GO
