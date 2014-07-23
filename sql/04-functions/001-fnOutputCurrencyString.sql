USE BudgetDB
GO

IF OBJECT_ID('dbo.fnOutputCurrencyString') IS NOT NULL
	DROP FUNCTION dbo.fnOutputCurrencyString
GO


CREATE FUNCTION dbo.fnOutputCurrencyString(
	@wbID INT				--	workbook ID
	,@m INT					--	month (integer between 1 and 36)
	,@bool NVARCHAR(128)	--	SQL string, logical comparison to determine
							--		whether to multiply by conversion rate
)
RETURNS NVARCHAR(2048)
AS
/*
summary:	>
			Function used in the main calculation procedure
			(dbo.output_live_converted) to feed its dynamic
			SQL a string for converting currency, based on
			whether a real workbook ID is provided.
			A workbook ID is a positive integer (IDENTITY column
			in dbo.workbooks); the frozen version procedure
			(dbo.create_frozen_version) calls it using a -1
			while the Excel templates will call it using
			their workbook ID.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-15
*/
BEGIN
	DECLARE @ret NVARCHAR(2048)
	
	IF ( @wbID > 0 )
	BEGIN	--	if workbook ID provided is real workbook ID, include string
		SET @ret = '*CASE WHEN ' + @bool + ' THEN 1 ELSE cr.[Month ' + CAST(@m AS NVARCHAR) + '] END '
	END
	ELSE
	BEGIN	--	return empty string if non-real workbook ID
		SET @ret = ''
	END
	
	RETURN @ret
END
GO
