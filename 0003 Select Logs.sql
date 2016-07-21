-- =============================================
-- Author:		Carlos Aguilar
-- Create date:  April 2016
-- =============================================

CREATE PROCEDURE dbo.SelectLogByDate
(
	@StartDate DATETIME,
    @EndDate DATETIME
)
AS
BEGIN
  
	CREATE TABLE #TRANSACTIONS
    (
    	[TIMESTAMP] DATETIME,
        STATION NVARCHAR(128),
    	[USER] NVARCHAR(128)
    )
    
    DECLARE @TABLE NVARCHAR(MAX)
    DECLARE @SQL NVARCHAR(MAX)
    DECLARE @ParmDefinition NVARCHAR(MAX);
    
    SET @ParmDefinition = N'@StartDate DATETIME, @EndDate DATETIME'

	DECLARE _LOGS_ CURSOR FOR 
	SELECT NAME FROM SYSOBJECTS WHERE TYPE = 'U' AND NAME LIKE '__LOG_%' 
    
	OPEN _LOGS_

	BEGIN TRY

  		BEGIN TRAN

 			FETCH NEXT FROM _LOGS_ INTO @TABLE

	  		WHILE (@@FETCH_STATUS = 0)
  			BEGIN
            
            	SELECT @SQL = 'INSERT INTO #TRANSACTIONS ([TIMESTAMP], STATION, [USER]) SELECT __TIME, __HOST_NAME, __DB_USER FROM ' + 
                	@TABLE + ' ' +
                    'WHERE __TIME BETWEEN @StartDate AND @EndDate'
                    
                EXECUTE sp_executesql @SQL, @ParmDefinition,
                      @StartDate = @StartDate,
                      @EndDate = @EndDate
            
            	FETCH NEXT FROM _LOGS_ INTO @TABLE
            END
        COMMIT
        
    END TRY
    BEGIN CATCH
    
    END CATCH
	CLOSE _LOGS_
    DEALLOCATE _LOGS_
    
    SELECT STATION, 
    		[USER],
            MIN([TIMESTAMP]) AS "START TIME",
            MAX([TIMESTAMP]) AS "END TIME",
            DATEDIFF(MINUTE, MIN([TIMESTAMP]), MAX([TIMESTAMP])) AS DURATION,
            COUNT(*) AS TRANSACTIONS
     FROM #TRANSACTIONS
     GROUP BY STATION, 
    		[USER]

END
GO