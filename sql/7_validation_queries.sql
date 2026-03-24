-- Validation queries
-- Used to inspect that the database data and relationships are correct


-- 1. Persons with their city
SELECT 
    person.P_Tal,
    person.FirstName,
    person.LastName,
    person.Zip,
    city.CityName
FROM Person person
JOIN City city
    ON person.Zip = city.Zip
ORDER BY person.P_Tal;


-- 2. Customers with their accounts and account types
SELECT 
    account.AccountNumber,
    person.FirstName,
    person.LastName,
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
    ON account.AccountTypeId = accountType.AccountTypeId
ORDER BY account.AccountNumber;


-- 3. Employees with personal information
SELECT 
    employee.P_Tal,
    person.FirstName,
    person.LastName,
    employee.Salary,
    employee.StartDate
FROM Employee employee
JOIN Person person
    ON employee.P_Tal = person.P_Tal
ORDER BY employee.P_Tal;


-- 4. Family relations in readable form
SELECT 
    familyRelation.FamilyRelationId,
    person1.FirstName || ' ' || person1.LastName AS Person1,
    relationshipType.TypeName AS RelationshipType,
    person2.FirstName || ' ' || person2.LastName AS Person2,
    familyRelation.StartDate,
    familyRelation.EndDate
FROM FamilyRelation familyRelation
JOIN Person person1
    ON familyRelation.Person1PTal = person1.P_Tal
JOIN Person person2
    ON familyRelation.Person2PTal = person2.P_Tal
JOIN RelationshipType relationshipType
    ON familyRelation.RelationshipTypeId = relationshipType.RelationshipTypeId
ORDER BY familyRelation.FamilyRelationId;


-- 5. Account access (permissions)
SELECT 
    accountAccess.AccountAccessId,
    person.FirstName || ' ' || person.LastName AS PersonName,
    accountAccess.AccountNumber,
    accountAccess.CanView,
    accountAccess.CanTransfer,
    accountAccess.StartDate,
    accountAccess.EndDate
FROM AccountAccess accountAccess
JOIN Person person
    ON accountAccess.PersonPTal = person.P_Tal
ORDER BY accountAccess.AccountAccessId;


-- 6. Draft transfers
SELECT 
    draftTransfer.DraftTransferId,
    draftTransfer.Amount,
    draftTransfer.TransferDate,
    draftTransfer.Status,
    draftTransfer.FromAccountNumber,
    draftTransfer.ToAccountNumber
FROM DraftTransfer draftTransfer
ORDER BY draftTransfer.DraftTransferId;


-- 7. Transaction records with type
SELECT 
    transactionRecord.TransactionId,
    transactionRecord.TransactionDate,
    transactionRecord.Amount,
    transactionRecord.Description,
    transactionRecord.AccountNumber,
    transactionType.TypeName AS TransactionType
FROM TransactionRecord transactionRecord
JOIN TransactionType transactionType
    ON transactionRecord.TransactionTypeId = transactionType.TransactionTypeId
ORDER BY transactionRecord.TransactionId;


-- 8. Active account access
SELECT 
    accountAccess.AccountAccessId,
    person.FirstName || ' ' || person.LastName AS PersonName,
    accountAccess.AccountNumber,
    accountAccess.CanView,
    accountAccess.CanTransfer,
    accountAccess.StartDate,
    accountAccess.EndDate
FROM AccountAccess accountAccess
JOIN Person person
    ON accountAccess.PersonPTal = person.P_Tal
WHERE accountAccess.EndDate IS NULL
   OR accountAccess.EndDate >= SYSDATE
ORDER BY accountAccess.AccountAccessId;


-- 9. Expired account access
SELECT 
    accountAccess.AccountAccessId,
    person.FirstName || ' ' || person.LastName AS PersonName,
    accountAccess.AccountNumber,
    accountAccess.CanView,
    accountAccess.CanTransfer,
    accountAccess.StartDate,
    accountAccess.EndDate
FROM AccountAccess accountAccess
JOIN Person person
    ON accountAccess.PersonPTal = person.P_Tal
WHERE accountAccess.EndDate < SYSDATE
ORDER BY accountAccess.AccountAccessId;
