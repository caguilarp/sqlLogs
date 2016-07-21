-- =============================================
-- Author:		Carlos Aguilar
-- Create date:  April 2016
-- Description:	 In case you need delete all the logs and triggers
-- =============================================

DECLARE @SCRIPT NVARCHAR(MAX)
DECLARE @TABLE NVARCHAR(MAX)
DECLARE @COLUMNS NVARCHAR(MAX)

DECLARE _LOGS_ CURSOR FOR 
	SELECT NAME FROM SYSOBJECTS WHERE TYPE = 'U' AND NAME NOT LIKE '__LOG_%' 
    
OPEN _LOGS_





  BEGIN TRAN



  FETCH NEXT FROM _LOGS_ INTO @TABLE

  WHILE (@@FETCH_STATUS = 0)
  BEGIN
  
BEGIN TRY  
  
    SET  @SCRIPT = 'DROP TRIGGER __LOG_DELETE_' + @TABLE
    EXEC (@SCRIPT)  
    
    SET  @SCRIPT = 'DROP TRIGGER __LOG_INSERT_' + @TABLE
    EXEC (@SCRIPT)  
    
    SET  @SCRIPT = 'DROP TRIGGER __LOG_UPDATE_' + @TABLE
    EXEC (@SCRIPT) 
    
    SET  @SCRIPT = 'DROP TABLE __LOG_' + @TABLE
    EXEC (@SCRIPT)   

END TRY

BEGIN CATCH

    PRINT 'ERROR: ' + ERROR_MESSAGE()
    
END CATCH
       
    FETCH NEXT FROM _LOGS_ INTO @TABLE

  END   
  
  COMMIT




CLOSE _LOGS_
DEALLOCATE _LOGS_