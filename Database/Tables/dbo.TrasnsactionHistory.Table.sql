/****

DEVELOPER: Andy S

HISTORY:

  v1.0.0 - Created Table.

****/

IF NOT EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'TransactionHistory' )
BEGIN
CREATE TABLE dbo.TransactionHistory
(
     AccountId INT                NOT NULL 
	,Debit     MONEY                  NULL
	,Credit    MONEY                  NULL
	,TransactionDTTM DATETIME2(0) NOT NULL
	,FOREIGN KEY ( AccountId) 
	 REFERENCES dbo.Account
);
END
GO
