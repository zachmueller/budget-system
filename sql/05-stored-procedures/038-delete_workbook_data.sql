USE BudgetDB
GO

IF OBJECT_ID('dbo.delete_workbook_data', 'P') IS NOT NULL
	DROP PROCEDURE dbo.delete_workbook_data
GO


CREATE PROCEDURE dbo.delete_workbook_data
	@wbID INT
AS
/*
summary:	>
			Used to delete old, unused workbooks
			from the database. Primarily for cleaning
			up old data that crowded the database
			from testing.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-22
*/

IF EXISTS (SELECT TOP 1 workbook_id FROM BudgetDB.dbo.workbooks WHERE workbook_id=@wbID)
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
	DELETE FROM BudgetDB.dbo.backup_formulas
	WHERE backup_id IN (SELECT backup_id FROM BudgetDB.dbo.backups WHERE workbook_id=@wbID)
	
	DELETE FROM BudgetDB.dbo.backups
	WHERE workbook_id=@wbID
	
	DELETE FROM BudgetDB.dbo.calculation_table_commission_attainment
	WHERE workbook_id=@wbID
	
	DELETE FROM BudgetDB.dbo.historical_table_cap_rates
	WHERE id IN (SELECT id FROM BudgetDB.dbo.frozen_versions WHERE workbook_id=@wbID)
	
	DELETE FROM BudgetDB.dbo.frozen_versions
	WHERE workbook_id=@wbID
	
	DELETE FROM BudgetDB.dbo.calculation_table_cap_rates
	WHERE id IN (SELECT id FROM BudgetDB.dbo.live_forecast WHERE workbook_id=@wbID)
	
	DELETE FROM BudgetDB.dbo.live_forecast
	WHERE workbook_id=@wbID
	
	DELETE FROM BudgetDB.dbo.workbook_business_units
	WHERE workbook_id=@wbID
	DELETE FROM BudgetDB.dbo.workbook_companies
	WHERE workbook_id=@wbID
	DELETE FROM BudgetDB.dbo.workbook_departments
	WHERE workbook_id=@wbID
	DELETE FROM BudgetDB.dbo.workbook_locations
	WHERE workbook_id=@wbID
	DELETE FROM BudgetDB.dbo.workbook_products
	WHERE workbook_id=@wbID
	DELETE FROM BudgetDB.dbo.workbook_scenarios
	WHERE workbook_id=@wbID
	DELETE FROM BudgetDB.dbo.workbook_teams
	WHERE workbook_id=@wbID
	
	DELETE FROM BudgetDB.dbo.workbooks
	WHERE workbook_id=@wbID
	
	COMMIT TRANSACTION
	END TRY
	
	BEGIN CATCH
	ROLLBACK TRANSACTION
	END CATCH
END

GO
