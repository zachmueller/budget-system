USE HFM_ActualsDB
GO

IF OBJECT_ID('dbo.create_actuals_table', 'P') IS NOT NULL
	DROP PROCEDURE dbo.create_actuals_table
GO


CREATE PROCEDURE dbo.create_actuals_table
	@yr INT			--	input for the year value
AS
/*
summary:	>
			Dynamically create a new actuals table
			based on the input year, if that table
			does not already exist.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-25
*/
SET NOCOUNT ON

--	skip table creation if already exists
IF OBJECT_ID(N'HFM_ActualsDB.dbo.actuals_' + CAST(@yr AS NVARCHAR)) IS NOT NULL RETURN

DECLARE @fullSQL NVARCHAR(MAX) = '
CREATE TABLE HFM_ActualsDB.dbo.actuals_' + CAST(@yr AS NVARCHAR) + ' (
	company_number NCHAR(3) NOT NULL
	,location_number NCHAR(3) NOT NULL
	,hfm_account_code NVARCHAR(100) NOT NULL
	,bu_number NVARCHAR(100) NOT NULL
	,dept_number NCHAR(4) NOT NULL
	,hfm_team_code NVARCHAR(100) NOT NULL
	,hfm_product_code NVARCHAR(100) NOT NULL
	,currency_code NCHAR(3) NOT NULL
	,[Month 1] DECIMAL(30,16)
	,[Month 2] DECIMAL(30,16)
	,[Month 3] DECIMAL(30,16)
	,[Month 4] DECIMAL(30,16)
	,[Month 5] DECIMAL(30,16)
	,[Month 6] DECIMAL(30,16)
	,[Month 7] DECIMAL(30,16)
	,[Month 8] DECIMAL(30,16)
	,[Month 9] DECIMAL(30,16)
	,[Month 10] DECIMAL(30,16)
	,[Month 11] DECIMAL(30,16)
	,[Month 12] DECIMAL(30,16)
	,CONSTRAINT pk_actuals_' + CAST(@yr AS NVARCHAR) + ' PRIMARY KEY 
		(company_number, location_number, hfm_account_code, bu_number
		,dept_number, hfm_team_code, hfm_product_code, currency_code)
)
'
BEGIN TRY
EXEC sp_executesql @fullSQL
END TRY

BEGIN CATCH
RETURN
END CATCH

GO
