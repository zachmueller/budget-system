USE BudgetDB
GO

IF DATABASE_PRINCIPAL_ID('finance_analyst') IS NOT NULL
	DROP ROLE finance_analyst
GO

IF DATABASE_PRINCIPAL_ID('fpa_analyst') IS NOT NULL
	DROP ROLE fpa_analyst
GO

--------------------------------------------------

--	database role for regular analysts who will read/write budget data
CREATE ROLE finance_analyst AUTHORIZATION dbo;

--	database role for Financial Planning & Analysis analysts who will 
--		control scenarios and dimension lists
CREATE ROLE fpa_analyst AUTHORIZATION dbo;

--------------------------------------------------

--	add permissions to each separate role
GRANT SELECT ON SCHEMA::dbo TO fpa_analyst, finance_analyst;

--	no analysts can view salary data directly
DENY SELECT ON OBJECT::dbo.salary_data TO fpa_analyst, finance_analyst;
DENY SELECT ON OBJECT::dbo.historical_table_salary_data TO fpa_analyst, finance_analyst;

--	no analysts can directly add to the log table
DENY EXECUTE ON OBJECT::dbo.log_add_entry TO finance_analyst, fpa_analyst;
DENY EXECUTE ON OBJECT::dbo.log_add_table_entry TO finance_analyst, fpa_analyst;

--	only regular finance analysts can push forecast/budget data
GRANT EXECUTE ON OBJECT::dbo.bulk_upload_excel_push_all_updates TO finance_analyst;

--	necessary for dbo.bulk_upload_excel_sbc sproc to be run by
--		FP&A analysts as it uses a dynamic SQL insert
GRANT INSERT ON OBJECT::dbo.calculation_table_sbc TO fpa_analyst;

--	only FP&A analysts can update Master Assumptions, add/change dimensions, create scenarios, etc.
GRANT EXECUTE ON OBJECT::dbo.bulk_upload_excel_base_bonus TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.bulk_upload_excel_bonus_payout TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.bulk_upload_excel_commissions_attainment TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.bulk_upload_excel_currency_rates TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.bulk_upload_excel_expense_payroll_taxes TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.bulk_upload_excel_per_headcount TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.bulk_upload_excel_percent_of_base TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.bulk_upload_excel_salaries TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.bulk_upload_excel_salary_payroll_taxes TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.bulk_upload_excel_sbc TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.create_frozen_version TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.create_rax_cons_scenario TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.update_workbook_activate TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.settings_update_accounts TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.settings_update_business_units TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.settings_update_companies TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.settings_update_cost_center_hierarchies TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.settings_update_departments TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.settings_update_divisions TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.settings_update_forecast_start_date TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.settings_update_locations TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.settings_update_products TO fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.settings_update_teams TO fpa_analyst;

--	all analysts can create and update workbooks (and use required data pulls, use backup functionality, etc.)
GRANT EXECUTE ON OBJECT::dbo.assumptions_base TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.assumptions_bonus TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.assumptions_bonus_payout TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.assumptions_commission TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.assumptions_expense_payroll_taxes TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.assumptions_local_actuals TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.assumptions_per_headcount TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.assumptions_percent_of_base TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.assumptions_salary_payroll_taxes TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.assumptions_sbc TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.backup_workbook TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.create_new_workbook TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.create_workbook_from_backup TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.excel_get_backup_workbook_options TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.excel_get_backups_for_workbook TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.excel_get_workbook_backup_info TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.excel_get_workbook_scenarios TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.excel_get_workbooks_with_backups TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_actual_start_date TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_business_units TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_categories TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_companies TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_currency_codes TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_departments TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_division_mapping TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_divisions TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_expense_items TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_forecast_start_date TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_forecast_workbooks TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_gl_accounts TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_job_titles TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_locations TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_product_consolidations TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_products TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_revenue_items TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_revenue_scenarios TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_scenarios TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_scenarios_all TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_team_consolidations TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_teams TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_workbook_scenarios TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.options_workbooks TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.output_live_converted TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.update_workbook_deactivate TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.update_workbook_dimensions TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.update_workbook_rename TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.update_workbook_scenarios TO finance_analyst, fpa_analyst;

--	all analysts can view analytics
GRANT EXECUTE ON OBJECT::dbo.analytics_budget_to_budget TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.analytics_current_heads TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.analytics_detailed_headcount TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.analytics_headcount TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.analytics_monthly_salary_detail TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.analytics_raw_data_dump TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.analytics_raw_pivot_data TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.analytics_upload_log TO finance_analyst, fpa_analyst;
GRANT EXECUTE ON OBJECT::dbo.analytics_workbook_info TO finance_analyst, fpa_analyst;
