-- =============================================
-- Author:		Carlos Aguilar
-- Create date:  April 2016
-- Description:	 Massive Creation of Trigger for Log Tables in a Database
-- =============================================

DECLARE @COLUMNS NVARCHAR(MAX)
DECLARE @SCRIPT NVARCHAR(MAX)
DECLARE @TABLE NVARCHAR(MAX)

DECLARE _LOGS_ CURSOR FOR 
	SELECT NAME FROM SYSOBJECTS WHERE TYPE = 'U' AND NAME NOT LIKE '__LOG_%'
    
OPEN _LOGS_



BEGIN TRY

  BEGIN TRAN

  FETCH NEXT FROM _LOGS_ INTO @TABLE

  WHILE (@@FETCH_STATUS = 0)
  BEGIN
      
  	SET @COLUMNS = ''

    SELECT @COLUMNS = @COLUMNS + '[' + T1.NAME + '], ' 
    FROM SYSOBJECTS T0 
        INNER JOIN SYSCOLUMNS T1 
            ON T0.ID = T1.ID 
    WHERE T0.TYPE = 'U' AND 
        T0.NAME NOT LIKE '__LOG_%' AND
        T0.NAME = @TABLE AND
        T1.XTYPE NOT IN (34, 35, 99)
  
    SELECT @SCRIPT = 'CREATE TRIGGER [dbo].[__LOG_INSERT_' + @TABLE + '] ON [dbo].[' + @TABLE + ']
                WITH ENCRYPTION, EXECUTE AS CALLER
                FOR INSERT
                AS
                BEGIN
                  INSERT INTO __LOG_' + @TABLE + '(' +
                  	@COLUMNS + '
                    __DB_USER,
                    __APP_NAME,
                    __HOST_NAME,
                    __IP_ADD,
                    __EVENT,
                    __TIME,
                    __PROTOCOL) 
                  SELECT ' + @COLUMNS + '
                        SUSER_SNAME() AS __DB_USER , 
                        APP_NAME  () AS __APP_NAME,
                        HOST_NAME () AS __HOST_NAME,
                        CONNECTIONPROPERTY(''client_net_address'') __IP_ADD,
                        ''I'' AS __EVENT,
                        GETDATE() AS __TIME,
                        CONNECTIONPROPERTY(''protocol_type'') AS __PROTOCOL
                  FROM INSERTED
                  
                END'

	  PRINT @SCRIPT
      
      EXEC (@SCRIPT)
      
      SELECT @SCRIPT = 'CREATE TRIGGER [dbo].[__LOG_UPDATE_' + @TABLE + '] ON [dbo].[' + @TABLE + ']
                WITH ENCRYPTION, EXECUTE AS CALLER
                FOR UPDATE
                AS
                BEGIN
                  INSERT INTO __LOG_' + @TABLE + '(' +
                  	@COLUMNS + '
                    __DB_USER,
                    __APP_NAME,
                    __HOST_NAME,
                    __IP_ADD,
                    __EVENT,
                    __TIME,
                    __PROTOCOL) 
                  SELECT ' + @COLUMNS + '
                        SUSER_SNAME() AS __DB_USER , 
                        APP_NAME  () AS __APP_NAME,
                        HOST_NAME () AS __HOST_NAME,
                        CONNECTIONPROPERTY(''client_net_address'') __IP_ADD,
                        ''U'' AS __EVENT,
                        GETDATE() AS __TIME,
                        CONNECTIONPROPERTY(''protocol_type'') AS __PROTOCOL
                  FROM INSERTED
                  
                END'

	  PRINT @SCRIPT
      
      EXEC (@SCRIPT)
      
      SELECT @SCRIPT = 'CREATE TRIGGER [dbo].[__LOG_DELETE_' + @TABLE + '] ON [dbo].[' + @TABLE + ']
                WITH ENCRYPTION, EXECUTE AS CALLER
                FOR DELETE
                AS
                BEGIN
                  INSERT INTO __LOG_' + @TABLE + '(' +
                  	@COLUMNS + '
                    __DB_USER,
                    __APP_NAME,
                    __HOST_NAME,
                    __IP_ADD,
                    __EVENT,
                    __TIME,
                    __PROTOCOL) 
                  SELECT ' + @COLUMNS + '
                        SUSER_SNAME() AS __DB_USER , 
                        APP_NAME  () AS __APP_NAME,
                        HOST_NAME () AS __HOST_NAME,
                        CONNECTIONPROPERTY(''client_net_address'') __IP_ADD,
                        ''D'' AS __EVENT,
                        GETDATE() AS __TIME,
                        CONNECTIONPROPERTY(''protocol_type'') AS __PROTOCOL
                  FROM DELETED
                  
                END'

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