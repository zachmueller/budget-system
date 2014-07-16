USE BudgetDB
GO

IF OBJECT_ID('dbo.fnOutputSelectPostMonths', 'FN') IS NOT NULL
	DROP FUNCTION dbo.fnOutputSelectPostMonths
GO


CREATE FUNCTION dbo.fnOutputSelectPostMonths(
	@wbID INT			--	workbook ID
	,@t NVARCHAR(15)	--	directly the table alias, indicates the run type. 
						--		determines whether to return NULLs for some fields
	,@a NVARCHAR(128)	--	specific "alias.field_name" to pull GL Account
)
RETURNS NVARCHAR(1024)
AS
/*
summary:	>
			Returns a SQL string to feed the primary calculation procedure
			that feeds both regular P&L refreshes as well as the
			dbo.create_frozen_versions procedure. This function
			returns the part of the SELECT statement that
			comes AFTER the [Month X]'s fields.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
*/
BEGIN
	DECLARE @ret NVARCHAR(1024) = CHAR(13)+CHAR(10)
	
	--	if for Frozen Version, select out different columns
	IF ( @wbID < 0 )
	BEGIN
		IF ( @t = 'lf' )
		BEGIN
			SET @ret = ',lf.forecast_method, lf.forecast_rate,ISNULL(lf.currency_code,cp.currency_code) currency_code
	,ct.category_name, lf.workbook_id, wb.workbook_name, lf.sheet_name, lf.excel_row
	,lf.created_by, lf.created_date, lf.last_updated_by, lf.last_updated_date'
		END
		ELSE
		--	if from SBC table
		BEGIN
			SET @ret = ',NULL forecast_method, NULL forecast_rate, cp.currency_code
	,NULL category_name, NULL workbook_id, NULL workbook_name, NULL sheet_name, NULL excel_row
	,NULL created_by, NULL created_date, NULL last_updated_by, NULL last_updated_date'
		END
	END
	ELSE
	--	For regular P&L output (valid workbook ID)
	BEGIN
		--	create output based on table
		IF ( @t = 'lf' )
		BEGIN
			SET @ret = @ret + ',lf.company_number [GL Company],lf.location_number [GL Location]' 
				+ ',' + @a + ' [GL Account],lf.hfm_team_code [GL Team],lf.bu_number [GL BU]' 
				+ ',lf.dept_number [GL Department],LEFT(lf.hfm_product_code,4) [GL Product]
	,ct.category_name [Category], ' + @t + '.id [id], ' + @t + '.workbook_id [Workbook]
	,' + @t + '.sheet_name [Sheet], ' + @t + '.excel_row [Row]
	,cch.parent1 [Parent1],cch.parent2 [Parent2],cch.parent3 [Parent3],cch.parent4 [Parent4]'
		END
		ELSE
		BEGIN
			IF ( @t = 'fv' )
			BEGIN
				--	frozen versions tables stores category name directly in its table
				SET @ret = @ret + ',fv.company_number [GL Company],fv.location_number [GL Location]'
					+ ',' + @a + ' [GL Account],fv.hfm_team_code [GL Team],fv.bu_number [GL BU]' 
					+ ',fv.dept_number [GL Department],LEFT(fv.hfm_product_code,4) [GL Product]
	,' + @t + '.category_name [Category], ' + @t + '.id [id], ' + @t + '.workbook_id [Workbook]
	,' + @t + '.sheet_name [Sheet], ' + @t + '.excel_row [Row]
	,cch.parent1 [Parent1],cch.parent2 [Parent2],cch.parent3 [Parent3],cch.parent4 [Parent4]'
			END
			ELSE
			BEGIN
				SET @ret = @ret + ',sbc.company_number [GL Company],sbc.location_number [GL Location]' 
					+ ',' + @a + ' [GL Account],sbc.hfm_team_code [GL Team],sbc.bu_number [GL BU]'
					+ ',sbc.dept_number [GL Department],''0000'' [GL Product]
	,NULL [Category], NULL [id], NULL [Workbook], NULL [Sheet], NULL [Row]
	,cch.parent1 [Parent1],cch.parent2 [Parent2],cch.parent3 [Parent3],cch.parent4 [Parent4]'
			END
		END
	END
	
	--	return final output
	RETURN @ret
END
GO
