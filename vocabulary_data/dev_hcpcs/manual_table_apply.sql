SET SERVEROUTPUT ON
SET ECHO OFF
SET VERIFY OFF
/* If any errors occurs - stop script execution and return error code */
WHENEVER SQLERROR EXIT SQL.SQLCODE
/*
 *****************************
 *  Log to file...    
 *****************************
*/
SPOOL '&1'

-- Create synonym for '&2' table
PROMPT Create synonym for '&2' table, if need...
DECLARE
  l_cnt NUMBER := 0;
BEGIN
  -- Check if need synonym
  SELECT COUNT(1) INTO l_cnt FROM USER_OBJECTS WHERE LOWER(object_name) = LOWER('&2') and LOWER(object_type) = 'table';
  IF (l_cnt < 1) THEN
    -- Drop if exists
BEGIN
   EXECUTE IMMEDIATE 'DROP SYNONYM &2';
EXCEPTION WHEN OTHERS THEN NULL;
END;
    -- Create synonym
    EXECUTE IMMEDIATE 'CREATE SYNONYM &2 FOR &3.&2';
  END IF;
END;
/
COMMIT;

PROMPT Applying &2 data to RELATIONSHIP_TO_CONCEPT table...
MERGE INTO RELATIONSHIP_TO_CONCEPT r2c
   USING (SELECT DISTINCT CONCEPT_CODE_1, CONCEPT_ID_2, PRECEDENCE, CONVERSION_FACTOR FROM &2) mt
   ON (DECODE(r2c.CONCEPT_CODE_1, mt.CONCEPT_CODE_1, 1, 0) = 1 AND DECODE(r2c.CONCEPT_ID_2, mt.CONCEPT_ID_2, 1, 0) = 1)
     WHEN MATCHED 
        THEN UPDATE SET r2c.PRECEDENCE = mt.PRECEDENCE, r2c.CONVERSION_FACTOR = mt.CONVERSION_FACTOR 
     WHEN NOT MATCHED 
        THEN INSERT (r2c.CONCEPT_CODE_1, r2c.CONCEPT_ID_2, r2c.PRECEDENCE, r2c.CONVERSION_FACTOR) 
             VALUES (mt.CONCEPT_CODE_1, mt.CONCEPT_ID_2, mt.PRECEDENCE, mt.CONVERSION_FACTOR);

COMMIT;

-- Delete synonym for '&2' table as unneeded
PROMPT Delete synonym for '&2' table as unneeded...
BEGIN
   EXECUTE IMMEDIATE 'DROP SYNONYM &2';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
COMMIT;

SPOOL OFF
EXIT