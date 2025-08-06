/****

DEVELOPER: Andy S

HISTORY:

  v1.0.0 - Created Procedure.

****/

CREATE OR ALTER PROCEDURE dbo.spNewEntry
(
     @AccountName     VARCHAR(128)
	,@Amount          MONEY
	,@TransactionType VARCHAR(10)
	,@DTTM            DATETIME2(0)
)
AS
BEGIN

	DECLARE @AccountId AS INT;

	SELECT @AccountId = Id FROM dbo.Account WHERE Name = @AccountName;

	IF @TransactionType IN ( 'CREDIT','C') BEGIN
		INSERT INTO dbo.TransactionHistory ( AccountId, Credit, TransactionDTTM )
		SELECT @AccountId, @Amount, @DTTM
	END ELSE IF @TransactionType IN ( 'DEBIT','D') BEGIN
		INSERT INTO dbo.TransactionHistory ( AccountId, Debit, TransactionDTTM )
		SELECT @AccountId, @Amount, @DTTM
	END

END
GO