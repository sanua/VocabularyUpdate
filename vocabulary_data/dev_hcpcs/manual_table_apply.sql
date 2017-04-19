SET ECHO OFF
SET VERIFY OFF
/* If any errors occurs - stop script execution and return error code */
WHENEVER SQLERROR EXIT SQL.SQLCODE
/*
 *****************************
 *  Log to file...    
 *****************************
*/
SPOOL &1

-- Delete sysnonym for '&2' table if exists
PROMPT Delete synonym for '&2' table if exists...
BEGIN
   EXECUTE IMMEDIATE 'DROP SYNONYM &2';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
COMMIT;

-- Create synonym for '&2' table
PROMPT  Create synonym for '&2' table...
CREATE SYNONYM &2 FOR DEV_HCPCS.&2; 

PROMPT Applying &2 data to RELATIONSHIP_TO_CONCEPT table...
MERGE INTO RELATIONSHIP_TO_CONCEPT r2c
   USING (SELECT DISTINCT CONCEPT_CODE_1, CONCEPT_ID_2, PRECEDENCE, CONVERSION_FACTOR FROM &2) mt
   ON (r2c.CONCEPT_CODE_1 = mt.CONCEPT_CODE_1 AND r2c.CONCEPT_ID_2 = mt.CONCEPT_ID_2)
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