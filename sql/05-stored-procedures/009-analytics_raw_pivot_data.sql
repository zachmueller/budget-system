USE BudgetDB
GO

IF OBJECT_ID('dbo.analytics_raw_pivot_data', 'P') IS NOT NULL
	DROP PROCEDURE dbo.analytics_raw_pivot_data
GO


CREATE PROCEDURE dbo.analytics_raw_pivot_data
	@monthStartDate DATE = NULL
	,@monthEndDate DATE = NULL
	,@curr NCHAR(3) = NULL				--	currency code
	,@sn NVARCHAR(256) = 'Forecast'		--	scenario name
	,@wbID INT = NULL					--	workbook ID
AS
/*
summary:	>
			Download unpivoted budget data for a desired scenario
			and date range for easier manipulation and analysis.
Revisions:
- version 1:
		Modification: Initial script for GitHub
		Author: Zach Mueller
		Date: 2014-07-15
*/
SET NOCOUNT ON

--	cancel query if scenario name does not exist
IF (SELECT TOP 1 scenario_id
	FROM BudgetDB.dbo.scenarios
	WHERE scenario_name=@sn) IS NULL
BEGIN
	SELECT 'Provided scenario name not found in the database.' error
	RETURN
END


--	check for invalid date entry
IF (@monthStartDate>=@monthEndDate)
BEGIN
	SELECT 'Invalid dates provided. Start date was greater then the end date.' error
	RETURN
END


--	find month integer range based on input dates
DECLARE @monthStart INT = (
	SELECT TOP 1 CASE 
			--	if input month prior to scenario start_date,
			--		start with [Month 1]
		WHEN ISNULL(@monthStartDate,start_date)<=start_date THEN 1
			--	if month within range, calculate month offset from start_date
		WHEN @monthStartDate BETWEEN start_date AND DATEADD(m,35,start_date)
			THEN DATEDIFF(m,start_date,@monthStartDate)+1
			--	if neither of the above are true, return 0 to error
			--		out in next validation check
		ELSE 0 END
	FROM BudgetDB.dbo.scenarios
	--	filter to input scenario
	WHERE scenario_name=@sn
)	--	similarly for end month
	,@monthEnd INT = (
	SELECT TOP 1 CASE
			--	if end date after last month of scenario, use [Month 36]
		WHEN ISNULL(@monthEndDate,DATEADD(m,35,start_date))>=DATEADD(m,35,start_date) THEN 36
			-- if month within range, calculate as difference from start_date+35 months
		WHEN @monthEndDate BETWEEN start_date AND DATEADD(m,35,start_date)
			THEN DATEDIFF(m,start_date,@monthEndDate)+1
			--	if neither of the above are true, return 37 to error
			--		out in next validation check
		ELSE 37 END
	FROM BudgetDB.dbo.scenarios
	--	filter to input scenario
	WHERE scenario_name=@sn
)

--	return if invalid month integers found (outside 1 and 36)
IF (@monthStart<1 OR @monthEnd>36)
BEGIN
	SELECT 'Unknown error with provided date range' error
	RETURN
END

--	find scenario start date
DECLARE @startDate DATE = (
	SELECT TOP 1 start_date
	FROM BudgetDB.dbo.scenarios
	WHERE scenario_name=@sn)

--	create temp table to store output
IF OBJECT_ID('tempdb..#TempOut') IS NOT NULL DROP TABLE #TempOut
CREATE TABLE #TempOut (
	[Scenario] NVARCHAR(256)
	,[Division] NVARCHAR(256)
	,[Company] NVARCHAR(256)
	,[Business Unit] NVARCHAR(256)
	,[Department] NVARCHAR(256)
	,[Team] NVARCHAR(256)
	,[Team Consolidation] NVARCHAR(256)
	,[Product] NVARCHAR(256)
	,[Location] NVARCHAR(256)
	,[Job Title] NVARCHAR(256)
	,[P&L Item] NVARCHAR(256)
	,[Description] NVARCHAR(256)
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
	,[Month 13] DECIMAL(30,16)
	,[Month 14] DECIMAL(30,16)
	,[Month 15] DECIMAL(30,16)
	,[Month 16] DECIMAL(30,16)
	,[Month 17] DECIMAL(30,16)
	,[Month 18] DECIMAL(30,16)
	,[Month 19] DECIMAL(30,16)
	,[Month 20] DECIMAL(30,16)
	,[Month 21] DECIMAL(30,16)
	,[Month 22] DECIMAL(30,16)
	,[Month 23] DECIMAL(30,16)
	,[Month 24] DECIMAL(30,16)
	,[Month 25] DECIMAL(30,16)
	,[Month 26] DECIMAL(30,16)
	,[Month 27] DECIMAL(30,16)
	,[Month 28] DECIMAL(30,16)
	,[Month 29] DECIMAL(30,16)
	,[Month 30] DECIMAL(30,16)
	,[Month 31] DECIMAL(30,16)
	,[Month 32] DECIMAL(30,16)
	,[Month 33] DECIMAL(30,16)
	,[Month 34] DECIMAL(30,16)
	,[Month 35] DECIMAL(30,16)
	,[Month 36] DECIMAL(30,16)
	,[GL Company] NVARCHAR(100)
	,[GL Location] NVARCHAR(100)
	,[GL Account] NVARCHAR(100)
	,[GL Team] NVARCHAR(100)
	,[GL BU] NVARCHAR(100)
	,[GL Department] NVARCHAR(100)
	,[GL Product] NVARCHAR(100)
	,[Category] NVARCHAR(256)
	,[id] INT
	,[Workbook] INT
	,[Sheet] NVARCHAR(50)
	,[Row] INT
	,[Parent1] NVARCHAR(256)
	,[Parent2] NVARCHAR(256)
	,[Parent3] NVARCHAR(256)
	,[Parent4] NVARCHAR(256)
)

--	run primary sproc to fill temp table with data
INSERT INTO #TempOut
EXEC BudgetDB.dbo.output_live_converted @curr, @wbID, @sn


--	select out the unpivoted data set
SELECT u.[Scenario], u.[Division], u.[Company], u.[Business Unit], u.[Department]
	,u.[Team], u.[Team Consolidation], u.[Product], u.[Location], u.[Job Title]
	,u.[P&L Item], u.[Description], CAST(cx.[Month] AS DATETIME) [Month], cx.[Amount]
	,u.[Category], u.id, u.[Workbook], u.[Sheet], u.[Row], u.Parent1, u.Parent2
	,u.Parent3, u.Parent4
FROM #TempOut u
CROSS APPLY (
	--	unpivot the data using CROSS APPLY, converting
	--	the different month's into dates
	VALUES (1,DATEADD(m,0,@startDate),[Month 1]),
(2,DATEADD(m,1,@startDate),[Month 2]),
(3,DATEADD(m,2,@startDate),[Month 3]),
(4,DATEADD(m,3,@startDate),[Month 4]),
(5,DATEADD(m,4,@startDate),[Month 5]),
(6,DATEADD(m,5,@startDate),[Month 6]),
(7,DATEADD(m,6,@startDate),[Month 7]),
(8,DATEADD(m,7,@startDate),[Month 8]),
(9,DATEADD(m,8,@startDate),[Month 9]),
(10,DATEADD(m,9,@startDate),[Month 10]),
(11,DATEADD(m,10,@startDate),[Month 11]),
(12,DATEADD(m,11,@startDate),[Month 12]),
(13,DATEADD(m,12,@startDate),[Month 13]),
(14,DATEADD(m,13,@startDate),[Month 14]),
(15,DATEADD(m,14,@startDate),[Month 15]),
(16,DATEADD(m,15,@startDate),[Month 16]),
(17,DATEADD(m,16,@startDate),[Month 17]),
(18,DATEADD(m,17,@startDate),[Month 18]),
(19,DATEADD(m,18,@startDate),[Month 19]),
(20,DATEADD(m,19,@startDate),[Month 20]),
(21,DATEADD(m,20,@startDate),[Month 21]),
(22,DATEADD(m,21,@startDate),[Month 22]),
(23,DATEADD(m,22,@startDate),[Month 23]),
(24,DATEADD(m,23,@startDate),[Month 24]),
(25,DATEADD(m,24,@startDate),[Month 25]),
(26,DATEADD(m,25,@startDate),[Month 26]),
(27,DATEADD(m,26,@startDate),[Month 27]),
(28,DATEADD(m,27,@startDate),[Month 28]),
(29,DATEADD(m,28,@startDate),[Month 29]),
(30,DATEADD(m,29,@startDate),[Month 30]),
(31,DATEADD(m,30,@startDate),[Month 31]),
(32,DATEADD(m,31,@startDate),[Month 32]),
(33,DATEADD(m,32,@startDate),[Month 33]),
(34,DATEADD(m,33,@startDate),[Month 34]),
(35,DATEADD(m,34,@startDate),[Month 35]),
(36,DATEADD(m,35,@startDate),[Month 36])
) cx ([Month Int], [Month], [Amount])
--	filter to only records between desired range
WHERE cx.[Month Int] BETWEEN @monthStart AND @monthEnd
--	exclude any records without meaningful data
AND ISNULL(cx.[Amount],0)<>0

GO
