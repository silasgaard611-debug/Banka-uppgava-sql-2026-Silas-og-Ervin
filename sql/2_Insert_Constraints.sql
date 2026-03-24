--Constraints

-- Account:
--The allowed overdraft can't be negative
ALTER TABLE ACCOUNT
ADD CONSTRAINT check_account_overdraft
CHECK(AllowedOverdraft >=0);

-- The balance cannot go below the allowed overdraft limit
ALTER TABLE ACCOUNT
ADD CONSTRAINT check_account_balance
CHECK(Balance >= -AllowedOverdraft);

-- AccountType:
-- Credit interest should be 0 or positive
ALTER TABLE AccountType
ADD CONSTRAINT check_accounttype_creditinterest
CHECK (CreditInterest >= 0);

-- Debit interest should be 0 or positive
ALTER TABLE AccountType
ADD CONSTRAINT check_accounttype_debitinterest
CHECK (DebitInterest >= 0);

-- overdraft interest should be 0 or positive
ALTER TABLE AccountType
ADD CONSTRAINT check_accounttype_overdraftinterest
CHECK (OverdraftInterest >= 0);

--Employee:
--Emplyee has to get a positive salary
ALTER TABLE EMPLOYEE
ADD CONSTRAINT check_employee_salary
CHECK(Salary > 0);


--Draft Transfer
--You can't transfer a negative or 0 sum
ALTER TABLE DRAFTTRANSFER
ADD CONSTRAINT check_drafttransfer_amount
CHECK(Amount > 0);

-- The transfer has to be between two seperate accounts
ALTER TABLE DRAFTTRANSFER
ADD CONSTRAINT check_drafttransfer_accounts
CHECK(FromAccountNumber <> ToAccountNumber);

--Transaction Record
ALTER TABLE TRANSACTIONRECORD
ADD CONSTRAINT check_transactionrecord_amount
CHECK(Amount <> 0);


--Family Relation
--You can't be related to yourself
ALTER TABLE FAMILYRELATION
ADD CONSTRAINT check_familyrelation_persons
CHECK(Person1PTal <> Person2PTal);

--End date can't be before start date
ALTER TABLE FAMILYRELATION
ADD CONSTRAINT check_familyrelation_dates
CHECK(EndDate IS NULL OR EndDate >= StartDate);

-- AccountAccess
-- CanView must be either 0 or 1
ALTER TABLE AccountAccess
ADD CONSTRAINT check_accountaccess_canview
CHECK (CanView IN (0,1));

-- CanTransfer must be either 0 or 1
ALTER TABLE AccountAccess
ADD CONSTRAINT check_accountaccess_cantransfer
CHECK (CanTransfer IN (0,1));

-- End date cannot be before start date
ALTER TABLE AccountAccess
ADD CONSTRAINT check_accountaccess_dates
CHECK (EndDate IS NULL OR EndDate >= StartDate);

-- if CanTransfer = 1, then CanView must also be 1
ALTER TABLE AccountAccess
ADD CONSTRAINT check_accountaccess_transfer_requires_view
CHECK (CanTransfer <= CanView);
