-- Procedures
-- These procedures handle the main business logic in the banking system


-- Procedure 1: book_draft_transfer
-- Books a draft transfer by:
-- 1. Checking that the draft transfer exists and is NEW
-- 2. Checking that the from-account has enough money / overdraft
-- 3. Inserting two transaction records
-- 4. Updating both account balances
-- 5. Marking the draft transfer as BOOKED

CREATE OR REPLACE PROCEDURE book_draft_transfer (
    p_draft_transfer_id IN NUMBER
)
IS
    v_amount NUMBER(12,2);
    v_transfer_date DATE;
    v_status VARCHAR2(20);
    v_from_account VARCHAR2(30);
    v_to_account VARCHAR2(30);

    v_from_balance NUMBER(12,2);
    v_from_overdraft NUMBER(12,2);
    v_to_balance NUMBER(12,2);

    v_transfer_type_id NUMBER;
BEGIN
    -- Find the transaction type id for transfers
    SELECT TransactionTypeId
    INTO v_transfer_type_id
    FROM TransactionType
    WHERE TypeName = 'Transfer';

    -- Get the draft transfer row
    SELECT Amount,
           TransferDate,
           Status,
           FromAccountNumber,
           ToAccountNumber
    INTO v_amount,
         v_transfer_date,
         v_status,
         v_from_account,
         v_to_account
    FROM DraftTransfer
    WHERE DraftTransferId = p_draft_transfer_id
    FOR UPDATE;

    -- Only NEW draft transfers can be booked
    IF v_status <> 'NEW' THEN
        RAISE_APPLICATION_ERROR(-20100,
            'Only draft transfers with status NEW can be booked.');
    END IF;

    -- Get the current balance and overdraft of the from-account
    SELECT Balance,
           AllowedOverdraft
    INTO v_from_balance,
         v_from_overdraft
    FROM Account
    WHERE AccountNumber = v_from_account
    FOR UPDATE;

    -- Get the current balance of the to-account
    SELECT Balance
    INTO v_to_balance
    FROM Account
    WHERE AccountNumber = v_to_account
    FOR UPDATE;

    -- Check if the from-account can cover the transfer
    IF v_from_balance - v_amount < -v_from_overdraft THEN
        RAISE_APPLICATION_ERROR(-20101,
            'The from-account does not have enough available funds.');
    END IF;

    -- Insert transaction on the from-account
    INSERT INTO TransactionRecord (
        TransactionDate,
        Amount,
        Description,
        AccountNumber,
        TransactionTypeId
    )
    VALUES (
        v_transfer_date,
        -v_amount,
        'Transfer to ' || v_to_account,
        v_from_account,
        v_transfer_type_id
    );

    -- Insert transaction on the to-account
    INSERT INTO TransactionRecord (
        TransactionDate,
        Amount,
        Description,
        AccountNumber,
        TransactionTypeId
    )
    VALUES (
        v_transfer_date,
        v_amount,
        'Transfer from ' || v_from_account,
        v_to_account,
        v_transfer_type_id
    );

    -- Update balances
    UPDATE Account
    SET Balance = Balance - v_amount
    WHERE AccountNumber = v_from_account;

    UPDATE Account
    SET Balance = Balance + v_amount
    WHERE AccountNumber = v_to_account;

    -- Mark the draft transfer as booked
    UPDATE DraftTransfer
    SET Status = 'BOOKED'
    WHERE DraftTransferId = p_draft_transfer_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20102,
            'Draft transfer or related account/transaction type was not found.');
END;
/

    
-- Procedure 2: calculate_monthly_interest
-- Calculates monthly interest for all accounts on a chosen date by:
-- 1. Reading the current account balance
-- 2. Finding the correct interest rate
-- 3. Inserting an interest transaction
-- 4. Updating the account balance
--
-- Notes:
-- - Positive balances use CreditInterest
-- - Negative balances use OverdraftInterest
-- - Loan accounts use DebitInterest if balance is negative
-- - The procedure skips accounts that already have a monthly interest
--   transaction on the same date

CREATE OR REPLACE PROCEDURE calculate_monthly_interest (
    p_to_date IN DATE
)
IS
    v_interest_type_id NUMBER;
    v_interest_rate NUMBER(5,2);
    v_interest_amount NUMBER(12,2);
    v_existing_interest NUMBER;
    v_account_type_name VARCHAR2(100);
BEGIN
    -- The date must not be null
    IF p_to_date IS NULL THEN
        RAISE_APPLICATION_ERROR(-20110,
            'The interest date cannot be null.');
    END IF;

    -- The date cannot be in the future
    IF p_to_date > TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20111,
            'Interest cannot be calculated for a future date.');
    END IF;

    -- Find the transaction type id for interest
    SELECT TransactionTypeId
    INTO v_interest_type_id
    FROM TransactionType
    WHERE TypeName = 'Interest';

    -- Loop through all accounts
    FOR account_row IN (
        SELECT account.AccountNumber,
               account.Balance,
               account.AccountTypeId,
               accountType.TypeName,
               accountType.CreditInterest,
               accountType.DebitInterest,
               accountType.OverdraftInterest
        FROM Account account
        JOIN AccountType accountType
            ON account.AccountTypeId = accountType.AccountTypeId
    ) LOOP

        -- Check whether interest has already been posted on this date
        SELECT COUNT(*)
        INTO v_existing_interest
        FROM TransactionRecord
        WHERE AccountNumber = account_row.AccountNumber
          AND TransactionTypeId = v_interest_type_id
          AND TransactionDate = p_to_date
          AND Description = 'Monthly interest';

        -- Skip this account if interest is already posted
        IF v_existing_interest = 0 THEN

            v_interest_rate := 0;
            v_interest_amount := 0;
            v_account_type_name := account_row.TypeName;

            -- Positive balance: use credit interest
            IF account_row.Balance > 0 THEN
                v_interest_rate := account_row.CreditInterest;
                v_interest_amount := ROUND(
                    (account_row.Balance * v_interest_rate / 100) / 12,
                    2
                );

            -- Negative balance: use debit interest for loan accounts,
            -- otherwise use overdraft interest
            ELSIF account_row.Balance < 0 THEN
                IF v_account_type_name = 'Loan' THEN
                    v_interest_rate := account_row.DebitInterest;
                ELSE
                    v_interest_rate := account_row.OverdraftInterest;
                END IF;

                v_interest_amount := ROUND(
                    (account_row.Balance * v_interest_rate / 100) / 12,
                    2
                );
            END IF;

            -- Only insert if the interest amount is not zero
            IF v_interest_amount <> 0 THEN
                INSERT INTO TransactionRecord (
                    TransactionDate,
                    Amount,
                    Description,
                    AccountNumber,
                    TransactionTypeId
                )
                VALUES (
                    p_to_date,
                    v_interest_amount,
                    'Monthly interest',
                    account_row.AccountNumber,
                    v_interest_type_id
                );

                UPDATE Account
                SET Balance = Balance + v_interest_amount
                WHERE AccountNumber = account_row.AccountNumber;
            END IF;

        END IF;

    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20112,
            'The transaction type Interest was not found.');
END;
/


------------------------------------
CREATE OR REPLACE PROCEDURE deposit_money (
    p_account_number IN VARCHAR2,
    p_amount         IN NUMBER,
    p_description    IN VARCHAR2 DEFAULT 'Deposit'
)
IS
    v_deposit_type_id NUMBER;
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20200,
            'Deposit amount must be greater than 0.');
    END IF;

    SELECT TransactionTypeId
    INTO v_deposit_type_id
    FROM TransactionType
    WHERE TypeName = 'Deposit';

    INSERT INTO TransactionRecord (
        TransactionDate,
        Amount,
        Description,
        AccountNumber,
        TransactionTypeId
    )
    VALUES (
        SYSDATE,
        p_amount,
        p_description,
        p_account_number,
        v_deposit_type_id
    );

    UPDATE Account
    SET Balance = Balance + p_amount
    WHERE AccountNumber = p_account_number;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20201,
            'Account not found.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20202,
            'Transaction type Deposit was not found.');
END;
/

--------------------------------------------
CREATE OR REPLACE PROCEDURE withdraw_money (
    p_account_number IN VARCHAR2,
    p_amount         IN NUMBER,
    p_description    IN VARCHAR2 DEFAULT 'Withdraw'
)
IS
    v_withdraw_type_id NUMBER;
    v_balance          NUMBER(12,2);
    v_overdraft        NUMBER(12,2);
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20203,
            'Withdrawal amount must be greater than 0.');
    END IF;

    SELECT Balance, AllowedOverdraft
    INTO v_balance, v_overdraft
    FROM Account
    WHERE AccountNumber = p_account_number
    FOR UPDATE;

    IF v_balance - p_amount < -v_overdraft THEN
        RAISE_APPLICATION_ERROR(-20204,
            'Withdrawal exceeds allowed overdraft.');
    END IF;

    SELECT TransactionTypeId
    INTO v_withdraw_type_id
    FROM TransactionType
    WHERE TypeName = 'Withdraw';

    INSERT INTO TransactionRecord (
        TransactionDate,
        Amount,
        Description,
        AccountNumber,
        TransactionTypeId
    )
    VALUES (
        SYSDATE,
        -p_amount,
        p_description,
        p_account_number,
        v_withdraw_type_id
    );

    UPDATE Account
    SET Balance = Balance - p_amount
    WHERE AccountNumber = p_account_number;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20205,
            'Account or transaction type Withdraw was not found.');
END;
/
