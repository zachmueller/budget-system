USE HFM_ActualsDB
GO

--	svc_hypdcom is the user login HFM uses to access/write to the Budget System
--		it requires db_owner access to create tables and write/delete data as necessary
CREATE USER [DOMAIN\svc_hypdcom] FOR LOGIN [DOMAIN\svc_hypdcom] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [DOMAIN\svc_hypdcom]
GO

--	other role needs are:
--		FP&A - access to read all tables' data and to EXECUTE the stored procedures
--		Finance Analysts - access to read all tables' data