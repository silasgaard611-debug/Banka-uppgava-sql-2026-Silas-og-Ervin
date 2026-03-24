-- Lookup data for system types (AccountType, TransactionType, RelationshipType)
-- Insert account types
INSERT INTO AccountType (TypeName, CreditInterest, DebitInterest, OverdraftInterest)
VALUES ('Savings', 2.50, 0.00, 7.00);

INSERT INTO AccountType (TypeName, CreditInterest, DebitInterest, OverdraftInterest)
VALUES ('Checking', 0.50, 0.00, 8.50);

INSERT INTO AccountType (TypeName, CreditInterest, DebitInterest, OverdraftInterest)
VALUES ('Loan', 0.00, 4.50, 0.00);


-- Insert transaction types
INSERT INTO TransactionType (TypeName)
VALUES ('Deposit');

INSERT INTO TransactionType (TypeName)
VALUES ('Withdraw');

INSERT INTO TransactionType (TypeName)
VALUES ('Transfer');

INSERT INTO TransactionType (TypeName)
VALUES ('Interest');


-- Insert relationship types
INSERT INTO RelationshipType (TypeName)
VALUES ('Spouse');

INSERT INTO RelationshipType (TypeName)
VALUES ('FormerSpouse');

INSERT INTO RelationshipType (TypeName)
VALUES ('BiologicalParent');

INSERT INTO RelationshipType (TypeName)
VALUES ('AdoptiveParent');

INSERT INTO RelationshipType (TypeName)
VALUES ('Guardian');

COMMIT;
