/****

DEVELOPER: Andy S

HISTORY:

  v1.0.0 - Created Table.
  v1.0.1 - New Column RecordedDTTM

****/

IF NOT EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Account' )
BEGIN
    CREATE TABLE dbo.Account
    (
    	 Id           INT          NOT NULL IDENTITY(1,1) PRIMARY KEY CLUSTERED
        ,Name         VARCHAR(128) NOT NULL
    	,IsEnabled    BIT          NOT NULL
        ,RecordedDTTM DATETIME2(0) NOT NULL		
    )
END
GO
