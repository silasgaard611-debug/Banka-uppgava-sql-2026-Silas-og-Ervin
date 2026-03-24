CREATE OR REPLACE FUNCTION validate_ptal(p_ptal IN VARCHAR2)
RETURN NUMBER
IS
    v_ptal   VARCHAR2(20);
    v_day    NUMBER;
    v_month  NUMBER;
    v_year   NUMBER;
    v_digit7 NUMBER;
    v_sum    NUMBER := 0;
    v_date   DATE;
BEGIN
    -- Simplified Faroese P-tal validation:
    -- checks format, valid date, and checksum
    -- century handling is simplified to 1900/2000 logic

    -- Remove hyphen and spaces
    v_ptal := REPLACE(REPLACE(TRIM(p_ptal), '-', ''), ' ', '');

    -- Must be exactly 9 digits
    IF LENGTH(v_ptal) <> 9 OR NOT REGEXP_LIKE(v_ptal, '^[0-9]{9}$') THEN
        RETURN 0;
    END IF;

    -- Extract date parts
    v_day    := TO_NUMBER(SUBSTR(v_ptal, 1, 2));
    v_month  := TO_NUMBER(SUBSTR(v_ptal, 3, 2));
    v_digit7 := TO_NUMBER(SUBSTR(v_ptal, 7, 1));

    -- Simplified century handling
    IF v_digit7 <= 4 THEN
        v_year := 1900 + TO_NUMBER(SUBSTR(v_ptal, 5, 2));
    ELSE
        v_year := 2000 + TO_NUMBER(SUBSTR(v_ptal, 5, 2));
    END IF;

    -- Validate date
    BEGIN
        v_date := TO_DATE(
            LPAD(v_day, 2, '0') ||
            LPAD(v_month, 2, '0') ||
            TO_CHAR(v_year),
            'DDMMYYYY'
        );
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END;

    -- Checksum validation
    v_sum :=
          3 * TO_NUMBER(SUBSTR(v_ptal, 1, 1))
        + 2 * TO_NUMBER(SUBSTR(v_ptal, 2, 1))
        + 7 * TO_NUMBER(SUBSTR(v_ptal, 3, 1))
        + 6 * TO_NUMBER(SUBSTR(v_ptal, 4, 1))
        + 5 * TO_NUMBER(SUBSTR(v_ptal, 5, 1))
        + 4 * TO_NUMBER(SUBSTR(v_ptal, 6, 1))
        + 3 * TO_NUMBER(SUBSTR(v_ptal, 7, 1))
        + 2 * TO_NUMBER(SUBSTR(v_ptal, 8, 1))
        + 1 * TO_NUMBER(SUBSTR(v_ptal, 9, 1));

    IF MOD(v_sum, 11) = 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
/
