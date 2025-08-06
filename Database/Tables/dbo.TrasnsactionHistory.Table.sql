/****

DEVELOPER: Andy S

HISTORY:

  v1.0.0 - Created Table.
  v1.0.1 - New column RecordedDTTM.
  v1.0.3 - Fix Bug. Foreign Key.
****/

IF NOT EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'TransactionHistory' )
BEGIN
CREATE TABLE dbo.TransactionHistory
(
     AccountId       INT          NOT NULL 
	,Debit           MONEY            NULL
	,Credit          MONEY            NULL
	,TransactionDTTM DATETIME2(0) NOT NULL
	,RecordedDTTM    DATETIME2(0) NOT NULL
	,FOREIGN KEY ( AccountId) 
	 REFERENCES dbo.Account (ID)
);
END
GO
