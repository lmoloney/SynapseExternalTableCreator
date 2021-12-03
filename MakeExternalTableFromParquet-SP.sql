CREATE PROCEDURE MakeExternalTableFromParquet
	@InputFilePath					VARCHAR(MAX),
	@ExternalTableFileLocation		VARCHAR(MAX),
	@ExternalTableFileSource		VARCHAR(MAX),
	@ExternalTableFileFormat		VARCHAR(MAX),
	@ExternalTableSchema			VARCHAR(MAX),
	@ExternalTableName				VARCHAR(MAX)
AS
--CREATE UIUD for View Name
DECLARE @ViewName VARCHAR(MAX);
SET @ViewName = CAST(NEWID() as VARCHAR(MAX));
--SELECT @VIEW;

--Generate SQL for View Creation
DECLARE @CreateView VARCHAR(MAX);
SET @CreateView = 'CREATE VIEW [' + @ViewName +'] as 
  SELECT * 
  FROM OPENROWSET(
					BULK ''' + @InputFilePath + ''',
					FORMAT = ''PARQUET''
                  ) AS [result]';
--SELECT @SQL1;

EXECUTE(@CreateView);

DECLARE @ExternalTablePrefix VARCHAR(MAX);
SET @ExternalTablePrefix = '''CREATE EXTERNAL TABLE [' + @ExternalTableSchema + '].[' + @ExternalTableName + '] (''';
--SELECT @ExternalTablePrefix

DECLARE @ExternalTableSuffix VARCHAR(MAX);
SET @ExternalTableSuffix = ''') WITH (LOCATION=''''' + @ExternalTableFileLocation + ''''', DATA_SOURCE = ' + @ExternalTableFileSource + ', FILE_FORMAT = ' + @ExternalTableFileFormat + ')''';
--SELECT @ExternalTableSuffix;

--GENERATE SQL for SCHEMA EXTRACTION
DECLARE @GenerateStatement VARCHAR(MAX);
SET @GenerateStatement = 'SELECT CONCAT(Prefix, RowStatement, Suffix) FROM (SELECT ' +
				@ExternalTablePrefix + ' as Prefix,
				STRING_AGG(
							CASE	WHEN DATA_TYPE = ''varchar''
									THEN CONCAT(COLUMN_NAME, '' '', DATA_TYPE,''('',CHARACTER_MAXIMUM_LENGTH,'')'')
									ELSE CONCAT(COLUMN_NAME, '' '', DATA_TYPE)
							END
							, '',''
							) as RowStatement, ' +
				@ExternalTableSuffix + 'as Suffix
			 FROM Information_schema.columns
			 WHERE table_name = ''' + @ViewName +''') Query';

EXECUTE(@GenerateStatement);

--Generate SQL for View DROP, be a tidy person
DECLARE @DROPVIEW VARCHAR(MAX);
SET @DROPVIEW = 'DROP VIEW [' + @ViewName +']';

EXECUTE(@DROPVIEW);
