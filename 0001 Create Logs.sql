-- =============================================
-- Author:		Carlos Aguilar
-- Create date:  April 2016
-- Description:	 Massive Creation of Log Tables in a Database
-- =============================================

DECLARE @SCRIPT NVARCHAR(MAX)
DECLARE @TABLE NVARCHAR(MAX)
DECLARE @COLUMNS NVARCHAR(MAX)

DECLARE _LOGS_ CURSOR FOR 
	SELECT NAME FROM SYSOBJECTS WHERE TYPE = 'U' AND NAME NOT LIKE '__LOG_%' 
    
OPEN _LOGS_



BEGIN TRY

  BEGIN TRAN

  FETCH NEXT FROM _LOGS_ INTO @TABLE

  WHILE (@@FETCH_STATUS = 0)
  BEGIN
      
  	SET @COLUMNS = ''

    SELECT @COLUMNS = @COLUMNS + '[' + T1.NAME + '] ' + T2.NAME + 
		CASE 
        	WHEN T1.XTYPE IN (106, 108) THEN
            	'(' + CONVERT(VARCHAR, T1.XPREC) + ', ' + CONVERT(VARCHAR, T1.XSCALE) + ')'		
            WHEN T1.XTYPE IN (173, 175, 42, 43, 239, 231, 41, 165, 167) THEN
            	'(' + CASE WHEN T1.LENGTH = -1 THEN 'MAX' ELSE CONVERT(VARCHAR, T1.LENGTH ) END  + ')'
			ELSE
            	''
         END
		 + ' NULL, '
    FROM SYSOBJECTS T0 
        INNER JOIN SYSCOLUMNS T1 
            ON T0.ID = T1.ID
        INNER JOIN sys.TYPES T2
        	ON T1.XTYPE = T2.SYSTEM_TYPE_ID 
    WHERE T0.TYPE = 'U' AND 
        T0.NAME NOT LIKE '__LOG_%' AND
        T0.NAME = @TABLE AND
        T1.XTYPE NOT IN (34, 35, 99) AND
        T2.NAME <> 'sysname'
  
    SELECT @SCRIPT = 
    'CREATE TABLE __LOG_' + @TABLE + '(' + @COLUMNS + '
        [__DB_USER] nvarchar(128) NULL,
  		[__APP_NAME] nvarchar(128) NULL,
		[__HOST_NAME] nvarchar(128) NULL,
  		[__IP_ADD] sql_variant NULL,
  		[__EVENT] varchar(1) NULL,
  		[__TIME] datetime  NULL,
  		[__PROTOCOL] sql_variant NULL) '
    
    PRINT @SCRIPT

    EXEC (@SCRIPT)

    SELECT @SCRIPT = 'DELETE FROM __LOG_' + @TABLE
    
    PRINT @SCRIPT

    EXEC (@SCRIPT)   
    
    FETCH NEXT FROM _LOGS_ INTO @TABLE

  END   
  
  COMMIT

END TRY
BEGIN CATCH

	ROLLBACK
    PRINT 'ERROR: ' + ERROR_MESSAGE()

END CATCH

CLOSE _LOGS_
DEALLOCATE _LOGS_