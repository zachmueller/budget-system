USE BudgetDB
GO

IF OBJECT_ID('dbo.fnOutputNarrowJoins') IS NOT NULL
	DROP FUNCTION dbo.fnOutputNarrowJoins
GO


CREATE FUNCTION dbo.fnOutputNarrowJoins(
	@wbID INT			--	workbook ID
	,@t NVARCHAR(15)	--	directly the table alias, indicates the run type.
)
RETURNS NVARCHAR(1024)
AS
/*
summary:	>
			Returns a SQL string to feed the primary calculation procedure
			that feeds both regular P&L refreshes as well as the
			dbo.create_frozen_versions procedure. This function
			returns the part of the JOIN statements that narrow
			sets to dimensions relevant to the provided workbook ID.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-16
*/
BEGIN
	DECLARE @ret NVARCHAR(1024)
	--	begin to fill return variable
	IF ( @wbID > 0 )
	BEGIN	--	for real workbook IDs
		SET @ret = 'LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=' + CAST(@wbID AS NVARCHAR) 
	END
	ELSE
	BEGIN	--	when run by dbo.create_frozen_versions (@wbID = -1)
		IF ( @t = 'lf' )
		BEGIN	--	include the narrowing JOINs for live_forecast tables,
				--	simply to pull in workbook name
			SET @ret = 'LEFT JOIN BudgetDB.dbo.workbooks wb ON wb.workbook_id=' + @t + '.workbook_id'
		END
		ELSE
		BEGIN	--	but not others (SBC, etc.) because workbook_id field does not exist in those
			SET @ret = ''
		END
	END
	
	--	only include INNER JOINs when not for dbo.create_frozen_versions (@wbID > 0)
	IF ( @wbID > 0 )
	BEGIN
		SET @ret = @ret + '
JOIN BudgetDB.dbo.workbook_business_units wbbu ON wbbu.workbook_id=wb.workbook_id
	AND ISNULL(wbbu.bu_number,' + @t + '.bu_number)=' + @t + '.bu_number
JOIN BudgetDB.dbo.workbook_companies wbcp ON wbcp.workbook_id=wb.workbook_id
	AND ISNULL(wbcp.company_number,' + @t + '.company_number)=' + @t + '.company_number
	AND COALESCE(cp.us_0_intl_1,wb.us_0_intl_1,'''')=COALESCE(wb.us_0_intl_1,'''')
JOIN BudgetDB.dbo.workbook_departments wbdp ON wbdp.workbook_id=wb.workbook_id
	AND ISNULL(wbdp.dept_number,' + @t + '.dept_number)=' + @t + '.dept_number
JOIN BudgetDB.dbo.workbook_locations wblc ON wblc.workbook_id=wb.workbook_id
	AND ISNULL(wblc.location_number,' + @t + '.location_number)=' + @t + '.location_number
JOIN BudgetDB.dbo.workbook_teams wbtm ON wbtm.workbook_id=wb.workbook_id
	AND ISNULL(wbtm.hfm_team_code,' + @t + '.hfm_team_code)=' + @t + '.hfm_team_code'
	
		IF ( @t <> 'sbc' )
		BEGIN	--	if for SBC calculation, do not include the product
				--	JOIN (as hfm_product_code field does not exist in SBC)
			SET @ret = @ret + '
JOIN BudgetDB.dbo.workbook_products wbpd ON wbpd.workbook_id=wb.workbook_id
	AND ISNULL(wbpd.hfm_product_code,' + @t + '.hfm_product_code)=' + @t + '.hfm_product_code'
		END
	END
	
	RETURN @ret
END
GO
