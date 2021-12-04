# SynapseExternalTableCreator
A pretty simple stored procedure that can be run in Synapse SQL Serverless and returns a full CREATE EXTERNAL TABLE statement which can be run against Synapse SQL Dedicated.

The Stored Procedure, called MakeExternalTableFromParquet takes 6 arguements:
1. InputFilePath - the location of the Parquet file / files being analysed e.g. https://[storage account].dfs.core.windows.net/[directories]/*.snappy.parquet
2. ExternalTableFileLocation - to be used in the LOCATION arguement within the generated EXTERNAL TABLE statement, generally this will need to be written as '/directory/subdirectory/'.
3. ExternalTableFileFormat - External Data Source to be used within the generated EXTERNAL TABLE statement.
4. ExternalTableSchema - Schema in which the EXTERNAL TABLE will be created in.
5. ExternalTableName - Table name of the EXTERNAL TABLE.

NOTE - ExternalTableFileLocation, ExternalTableFileFormat, ExternalTableSchema and ExternalTableName are purely used for generating the CREATE EXTERNAL TABLE statement, there is no validation etc on this.

## Purpose
Generating a CREATE EXTERNAL TABLE statement can be a pain, whilst tools like the Synapse Workspace can do this automatically (through the GUI) and Synapse Pipelines / Azure Data Factory can also do this as part of a COPY activity - that is not always suitable for all needs.

## Notes
Test coveragge for this is laughably bad (sorry), so your mileage my vary but in the 2 dozen different parquet files I tested with, it worked well enough. I think there is plenty of scope for improvements (see below) and making it more efficient - but hopefully in it's current form it helps.

This stored procedure is built around a couple of steps:
1. Create a view using OPENROWSET using a NEWID() as the view name.
2. Generate the first part of the create external table statement - basically up to the where each column name and it's data type is specified, this part uses the ExternalTableSchema and ExternalTableName parameters defined when calling the stored procedure.
3. Generate the last part of the create external table statement - basically everything after where each column name and it's data type is specified, this part uses the ExternalTableFileLocation and ExternalTableFileFormat parameters defined when calling the stored procedure.
4. Extract details from INFORMATION_SCHEMA.COLUMNS based on the VIEW created in step 1, with some logic for capturing VARCHARs.
5. Using a combination of CONCAT and STRING_AGG to bring together step 2, step 4 and step 3 (n.b. step 4 and this step actually happen in a single step).
6. Drop the view

The output from Step 5 is all that should be returned from the Stored Procedure, you can then run this on a Synapse SQL Dedicated environment.

Unfortunately using sp_describe_first_result_set isn't very workable, so the creation of the view seems like the easiest approach - let me know if you can find a better way (noting Synapse SQL Serverless doesn't have temp tables!).

## TODO
Oh so very much (not prioritized)
1. The documentation needs to be improved - probably a diagram would help
2. Error handling / rollback of the view if this errors
3. Simplify the inputs?
4. Look at efficiency options - variable is very lazily a VARCHAR(MAX).
5. Not sure I love the name of the Stored Procedure
6. Clean up the code (properly comment it, remove invalid calls which I have commented out)
7. Plenty more testing.
