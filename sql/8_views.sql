-- Views
-- These views are used to present important data in a simpler way


-- 1. Customer account overview
-- Shows each customer with their account and account type
CREATE OR REPLACE VIEW CustomerAccountOverview AS
SELECT
    person.P_Tal,
    person.FirstName,
    person.LastName,
    account.AccountNumber,
    accountType.TypeName AS AccountType,
    account.Balance,
    account.AllowedOverdraft,
    account.CreatedDate
FROM Account account
JOIN Customer customer
    ON account.CustomerPTal = customer.P_Tal
JOIN Person person
    ON customer.P_Tal = person.P_Tal
JOIN AccountType accountType
    ON account.AccountTypeId = accountType.AccountTypeId;


-- 2. Customer total balance
-- Shows the total balance across all accounts for each customer
CREATE OR REPLACE VIEW CustomerTotalBalance AS
SELECT
    person.P_Tal,
    person.FirstName,
    person.LastName,
    SUM(account.Balance) AS TotalBalance
FROM Account account
JOIN Customer customer
    ON account.CustomerPTal = customer.P_Tal
JOIN Person person
    ON customer.P_Tal = person.P_Tal
GROUP BY
    person.P_Tal,
    person.FirstName,
    person.LastName;


-- 3. Number of accounts per customer
-- Shows how many accounts each customer has
CREATE OR REPLACE VIEW CustomerAccountCount AS
SELECT
    person.P_Tal,
    person.FirstName,
    person.LastName,
    COUNT(account.AccountNumber) AS NumberOfAccounts
FROM Account account
JOIN Customer customer
    ON account.CustomerPTal = customer.P_Tal
JOIN Person person
    ON customer.P_Tal = person.P_Tal
GROUP BY
    person.P_Tal,
    person.FirstName,
    person.LastName;


-- 4. Account statement view
-- Shows account transactions in a readable way
CREATE OR REPLACE VIEW AccountStatementView AS
SELECT
    transactionRecord.AccountNumber,
    transactionRecord.TransactionDate,
    transactionType.TypeName AS TransactionType,
    transactionRecord.Description,
    transactionRecord.Amount
FROM TransactionRecord transactionRecord
JOIN TransactionType transactionType
    ON transactionRecord.TransactionTypeId = transactionType.TransactionTypeId;


-- 5. Active account access
-- Shows only active permissions for accounts
CREATE OR REPLACE VIEW ActiveAccountAccess AS
SELECT
    person.P_Tal,
    person.FirstName,
    person.LastName,
    accountAccess.AccountNumber,
    accountAccess.CanView,
    accountAccess.CanTransfer,
    accountAccess.StartDate,
    accountAccess.EndDate
FROM AccountAccess accountAccess
JOIN Person person
    ON accountAccess.PersonPTal = person.P_Tal
WHERE accountAccess.EndDate IS NULL
   OR accountAccess.EndDate >= SYSDATE;
