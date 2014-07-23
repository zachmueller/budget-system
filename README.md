# Budget System
- Built to support Rackspace Finance Department
- Back end: SQL Server 2008 R2 (R710, 16 cores, 24GB RAM)
- Front end: Microsoft Excel, 2010 and up
- Formal system name: Budget to Actual Database Automation Support System (BADASS)

## Primary Features
1. Maintains Forecast Detail
 - Quickly filter P&L by any dimension (leveraging Excel Slicers)
 - Custom analytics on headcount related costs
 - Find and update errors in a few clicks

2. Multiple Scenarios
 - Compare drivers of changes from budget to budget
 - Iterate often without worry: system can handle savings thousands of scenarios

3. Integrated Actuals
 - Direct link with Hyperion Financial Management
 - View multi-year P&L and quickly toggle between Actual and Budget scenarios

4. Automation
 - Built-in forecasting methodologies
 - Centralized company-wide assumptions
 - Vast drilling capabilities, all the way down to journal entry detail for Actuals
 - Double-click creation of Budget to Actual P&L views
 - Backup features allow for easy iteration of new features

## Python Script
 - combine.py
 - Inputs: -i <input folder> -o <output file> -t <file type>
 - Combines SQL script files together into one file, for easy database creation
 - Walks recursively through subfolders and their files
 - Example command line execution coming soon...

## Next Steps
- Development towards further improvements has largely stopped, pending job hunting results. May nonetheless refactor main calculation procedure (dbo.output_live_converted) as it is overly complicated.
- Continue cleaning up and documenting database scripts
- Upload unlocked versions of Excel files (main template as well as Master Assumptions)
- Potentially create a fully functional and publicly accessible dummy data set for anyone to test using the system

---

*Work in Progress*: Cleaning up SQL scripts and their file structure to be more GitHub-friendly. Will add scripts as time permits.

2014-07-14: Created all necessary SQL scripts prefixed with 3 digits to order them properly to build the full database. Will write a Python script to combine all files into one script to execute for a build.