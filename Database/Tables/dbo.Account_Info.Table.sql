/****

DEVELOPER: Andy S

HISTORY:

  v1.0.2 - Created Table.
  v1.0.3 - Fix Bug. Foreign Key, If not exists...

****/

IF NOT EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Account_Info' )
BEGIN
    CREATE TABLE dbo.Account_Info
    (
    	 Fk_Id           INT          NOT NULL 
        ,AccountType     VARCHAR(40)  NOT NULL  --User, Elevated, Admin
        ,AccountOpenDTTM DATETIME2(0) NOT NULL
        ,RecordedDTTM    DATETIME2(0) NOT NULL		
        ,FOREIGN KEY (FK_Id) 
         REFERENCES dbo.Account (Id)
    )
END
GO
