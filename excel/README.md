# Template Files
1. BG3 - Template.xlsm
2. Master Assumptions - US.xlsm

---

## BG3 - Template.xlsm
- Template to build main forecasting and Budget to Actual viewing workbooks
- "BG3" stands for "Budget Grabber 3", originating from the early iterations of the system
- Global variable, BudgetMacros module: set connStr variable to connection string for Budget System database
- Global variable, BudgetMacros module: set jeConnStr variable to connection string for Oracle database
- Global variable, BudgetMacros module: set pwd variable to workbook password

## Master Assumptions - US.xlsm
- Controls system settings and main forecast assumptions
- Global variable, BudgetDB module: set connStr variable to connection string for Budget System database
- Global variable, BudgetDB module: set pwd variable to workbook password
- Recommended to lock workbook (when saving as, Tools -> General Options -> "Password to open") using same password as above