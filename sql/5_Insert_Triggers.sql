-- Triggers

-- Account created date cannot be a future date
CREATE OR REPLACE TRIGGER trigger_account_check_createddate
BEFORE INSERT OR UPDATE ON Account
FOR EACH ROW
BEGIN
    IF :NEW.CreatedDate > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001,
            'CreatedDate cannot be in the future.');
    END IF;
END;
/

-- Employee start date cannot be in the future
CREATE OR REPLACE TRIGGER trigger_employee_check_startdate
BEFORE INSERT OR UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF :NEW.StartDate > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Employee StartDate cannot be in the future.');
    END IF;
END;
/

-- Transaction date cannot be in the future
CREATE OR REPLACE TRIGGER trigger_transactionrecord_check_date
BEFORE INSERT OR UPDATE ON TransactionRecord
FOR EACH ROW
BEGIN
    IF :NEW.TransactionDate > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20003,
            'TransactionDate cannot be in the future.');
    END IF;
END;
/

-- Stop a booked draft transfer from being changed
CREATE OR REPLACE TRIGGER trigger_drafttransfer_no_update_booked
BEFORE UPDATE ON DraftTransfer
FOR EACH ROW
BEGIN
    IF :OLD.Status = 'BOOKED' THEN
        RAISE_APPLICATION_ERROR(-20005,
            'A booked transfer cannot be updated.');
    END IF;
END;
/

-- If status is not given, set it to NEW
CREATE OR REPLACE TRIGGER trigger_drafttransfer_default_status
BEFORE INSERT ON DraftTransfer
FOR EACH ROW
BEGIN
    IF :NEW.Status IS NULL THEN
        :NEW.Status := 'NEW';
    END IF;
END;
/

-- Validate Faroese P-tal before insert or update
CREATE OR REPLACE TRIGGER trigger_person_validate_ptal
BEFORE INSERT OR UPDATE ON Person
FOR EACH ROW
BEGIN
    IF validate_ptal(:NEW.P_Tal) = 0 THEN
        RAISE_APPLICATION_ERROR(-20006,
            'Invalid P-tal.');
    END IF;
END;
/
