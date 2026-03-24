-- Test data to be able to test the database


-- 1. CITIES

INSERT INTO City (Zip, CityName)
VALUES ('100', 'Torshavn');

INSERT INTO City (Zip, CityName)
VALUES ('700', 'Klaksvik');

INSERT INTO City (Zip, CityName)
VALUES ('800', 'Tvoryri');


-- 2. PERSONS

-- Anna: parent / customer
INSERT INTO Person (P_Tal, FirstName, LastName, Zip)
VALUES ('110580-126', 'Anna', 'Hansen', '100');

-- Petur: employee
INSERT INTO Person (P_Tal, FirstName, LastName, Zip)
VALUES ('030375-009', 'Petur', 'Olsen', '700');

-- Eva: adult customer
INSERT INTO Person (P_Tal, FirstName, LastName, Zip)
VALUES ('220795-217', 'Eva', 'Johannesen', '100');

-- Maria: minor child
INSERT INTO Person (P_Tal, FirstName, LastName, Zip)
VALUES ('150410-576', 'Maria', 'Olsen', '100');

-- Hans: adult child
INSERT INTO Person (P_Tal, FirstName, LastName, Zip)
VALUES ('200805-577', 'Hans', 'Ellefsen', '800');

-- Sara: guardian
INSERT INTO Person (P_Tal, FirstName, LastName, Zip)
VALUES ('090988-018', 'Sara', 'Mikkelsen', '700');


-- 3. CUSTOMERS

INSERT INTO Customer (P_Tal, CommentText)
VALUES ('110580-126', 'Main customer and parent');

INSERT INTO Customer (P_Tal, CommentText)
VALUES ('220795-217', 'Adult customer with own account');

INSERT INTO Customer (P_Tal, CommentText)
VALUES ('150410-576', 'Minor customer account');

INSERT INTO Customer (P_Tal, CommentText)
VALUES ('200805-577', 'Adult child with own account');


-- 4. EMPLOYEES

INSERT INTO Employee (P_Tal, Salary, StartDate)
VALUES ('030375-009', 35000.00, DATE '2023-01-15');


-- 5. ACCOUNTS

-- Anna: checking account
INSERT INTO Account (
    AccountNumber, Balance, AllowedOverdraft, CreatedDate, CustomerPTal, AccountTypeId
)
VALUES (
    'ACC1001', 15000.00, 2000.00, DATE '2024-01-10', '110580-126', 2
);

-- Eva: savings account
INSERT INTO Account (
    AccountNumber, Balance, AllowedOverdraft, CreatedDate, CustomerPTal, AccountTypeId
)
VALUES (
    'ACC1002', 32000.00, 0.00, DATE '2024-02-12', '220795-217', 1
);

-- Maria: minor child savings account
INSERT INTO Account (
    AccountNumber, Balance, AllowedOverdraft, CreatedDate, CustomerPTal, AccountTypeId
)
VALUES (
    'ACC1003', 2500.00, 0.00, DATE '2025-03-01', '150410-576', 1
);

-- Hans: adult child checking account
INSERT INTO Account (
    AccountNumber, Balance, AllowedOverdraft, CreatedDate, CustomerPTal, AccountTypeId
)
VALUES (
    'ACC1004', 6000.00, 500.00, DATE '2023-06-20', '200805-577', 2
);


-- 6. FAMILY RELATIONS

-- Anna is biological parent of Maria
INSERT INTO FamilyRelation (
    Person1PTal, Person2PTal, StartDate, EndDate, RelationshipTypeId
)
VALUES (
    '110580-126', '150410-576', DATE '2010-04-15', NULL, 3
);

-- Anna is biological parent of Hans
INSERT INTO FamilyRelation (
    Person1PTal, Person2PTal, StartDate, EndDate, RelationshipTypeId
)
VALUES (
    '110580-126', '200805-577', DATE '2005-08-20', NULL, 3
);

-- Sara is guardian of Maria
INSERT INTO FamilyRelation (
    Person1PTal, Person2PTal, StartDate, EndDate, RelationshipTypeId
)
VALUES (
    '090988-018', '150410-576', DATE '2024-01-01', NULL, 5
);


-- 7. ACCOUNT ACCESS

-- Anna can view and transfer on Maria's account while Maria is a minor
INSERT INTO AccountAccess (
    PersonPTal, AccountNumber, CanView, CanTransfer, StartDate, EndDate
)
VALUES (
    '110580-126', 'ACC1003', 1, 1, DATE '2025-03-01', DATE '2028-04-15'
);

-- Sara as guardian can also view Maria's account, but not transfer
INSERT INTO AccountAccess (
    PersonPTal, AccountNumber, CanView, CanTransfer, StartDate, EndDate
)
VALUES (
    '090988-018', 'ACC1003', 1, 0, DATE '2024-01-01', NULL
);

-- Anna had access to Hans' account before he turned 18, but it has ended
INSERT INTO AccountAccess (
    PersonPTal, AccountNumber, CanView, CanTransfer, StartDate, EndDate
)
VALUES (
    '110580-126', 'ACC1004', 1, 1, DATE '2018-01-01', DATE '2023-08-20'
);


-- 8. DRAFT TRANSFERS

-- New transfer from Anna to Eva
INSERT INTO DraftTransfer (
    Amount, TransferDate, Status, FromAccountNumber, ToAccountNumber
)
VALUES (
    750.00, DATE '2026-03-10', 'NEW', 'ACC1001', 'ACC1002'
);

-- Booked transfer from Eva to Maria
INSERT INTO DraftTransfer (
    Amount, TransferDate, Status, FromAccountNumber, ToAccountNumber
)
VALUES (
    300.00, DATE '2026-03-11', 'BOOKED', 'ACC1002', 'ACC1003'
);


-- 9. TRANSACTION RECORDS

-- Anna deposit
INSERT INTO TransactionRecord (
    TransactionDate, Amount, Description, AccountNumber, TransactionTypeId
)
VALUES (
    DATE '2026-03-01', 5000.00, 'Initial deposit', 'ACC1001', 1
);

-- Eva deposit
INSERT INTO TransactionRecord (
    TransactionDate, Amount, Description, AccountNumber, TransactionTypeId
)
VALUES (
    DATE '2026-03-02', 12000.00, 'Salary deposit', 'ACC1002', 1
);

-- Maria deposit
INSERT INTO TransactionRecord (
    TransactionDate, Amount, Description, AccountNumber, TransactionTypeId
)
VALUES (
    DATE '2026-03-03', 500.00, 'Gift deposit', 'ACC1003', 1
);

-- Hans withdrawal
INSERT INTO TransactionRecord (
    TransactionDate, Amount, Description, AccountNumber, TransactionTypeId
)
VALUES (
    DATE '2026-03-04', -200.00, 'ATM withdrawal', 'ACC1004', 2
);

-- Transfer transaction on Anna's account
INSERT INTO TransactionRecord (
    TransactionDate, Amount, Description, AccountNumber, TransactionTypeId
)
VALUES (
    DATE '2026-03-05', -750.00, 'Transfer to Eva', 'ACC1001', 3
);

-- Transfer transaction on Eva's account
INSERT INTO TransactionRecord (
    TransactionDate, Amount, Description, AccountNumber, TransactionTypeId
)
VALUES (
    DATE '2026-03-05', 750.00, 'Transfer from Anna', 'ACC1002', 3
);

-- Interest transaction on Eva's savings account
INSERT INTO TransactionRecord (
    TransactionDate, Amount, Description, AccountNumber, TransactionTypeId
)
VALUES (
    DATE '2026-03-20', 40.00, 'Monthly interest', 'ACC1002', 4
);

COMMIT;
