USE BudgetDB
GO

IF OBJECT_ID('dbo.bulk_upload_excel_currency_rates', 'P') IS NOT NULL
	DROP PROCEDURE dbo.bulk_upload_excel_currency_rates
GO


CREATE PROCEDURE dbo.bulk_upload_excel_currency_rates
	@uploadInput bulk_upload_currency_rates READONLY
AS
/*
summary:	>
			Used by FP&A analysts to upload new
			FX rate assumptions to be used for
			converting from each record's local
			currency into any desired output
			currency.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/
--	prevent intermittent queries from interfering with Excel
SET NOCOUNT ON

--	update CONTEXT_INFO for trigger
DECLARE @ci VARBINARY(128) = CAST('sproc:bulk_upload_excel_currency_rates' AS VARBINARY(128))
SET CONTEXT_INFO @ci

--	check for invalid currency codes
IF (SELECT COUNT(*)
	FROM @uploadInput ui
	LEFT JOIN BudgetDB.dbo.currencies fcr
	ON fcr.currency_code=ui.from_currency
	LEFT JOIN BudgetDB.dbo.currencies tcr
	ON tcr.currency_code=ui.to_currency
	WHERE fcr.currency_code IS NULL
	OR tcr.currency_code IS NULL)>0
BEGIN
	SELECT 'Invalid currency code provided, please refresh the currency'
		+ ' code reference table and try uploading again.' o
	RETURN
END

--	collect forecast start date in variable
DECLARE @startDate DATE = (SELECT TOP 1 start_date 
	FROM BudgetDB.dbo.scenarios WHERE scenario_name='Forecast')

BEGIN TRY
BEGIN TRANSACTION

--	pivot the input currency rates to the database format and merge with the currency rates table
MERGE BudgetDB.dbo.currency_rates cr
USING (SELECT from_currency, to_currency, conversion_rate
	,DATEADD(m,CAST(LTRIM(RIGHT(col,2)) AS INT)-1,@startDate) conversion_month
FROM (
	SELECT from_currency, to_currency,[Month 1],[Month 2],[Month 3],[Month 4],[Month 5]
	,[Month 6],[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12]
	,[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
	,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30]
	,[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36]
	FROM @uploadInput
) p
UNPIVOT (conversion_rate FOR col IN
	([Month 1],[Month 2],[Month 3],[Month 4],[Month 5],[Month 6]
	,[Month 7],[Month 8],[Month 9],[Month 10],[Month 11],[Month 12]
	,[Month 13],[Month 14],[Month 15],[Month 16],[Month 17],[Month 18]
	,[Month 19],[Month 20],[Month 21],[Month 22],[Month 23],[Month 24]
	,[Month 25],[Month 26],[Month 27],[Month 28],[Month 29],[Month 30]
	,[Month 31],[Month 32],[Month 33],[Month 34],[Month 35],[Month 36])
) AS unpvt) ui
ON ui.from_currency=cr.from_currency AND ui.to_currency=cr.to_currency
AND cr.conversion_type='AVG_RATE' AND ui.conversion_month=cr.conversion_month
AND cr.scenario_id IS NULL
WHEN MATCHED THEN
	UPDATE SET cr.conversion_rate=ui.conversion_rate
WHEN NOT MATCHED THEN
	INSERT (scenario_id, from_currency, to_currency, conversion_type
		,conversion_month, conversion_rate)
	VALUES (NULL, ui.from_currency, ui.to_currency, 'AVG_RATE'
		,ui.conversion_month, ui.conversion_rate)
;


COMMIT TRANSACTION

SELECT 'Database successfully updated.' o, 1 n

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

END TRY


BEGIN CATCH
--	rollback transaction
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

--	set CONTEXT_INFO back to NULL
SET CONTEXT_INFO 0x

--	return error message to user
SELECT 'An error occurred in the database while attemping to update the exchange rates:' 
	+ CHAR(13)+CHAR(10) + ERROR_MESSAGE() + ' Severity=' + CAST(ERROR_SEVERITY() AS nvarchar(2))
END CATCH

GO
