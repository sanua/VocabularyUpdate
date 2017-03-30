SET LINESIZE 1024
SET ECHO OFF
SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET NEWPAGE NONE
-- SET COLSEP ';'

COLUMN exp_file_name new_val exp_file_name
SELECT '&1'|| '/' || '&2' AS exp_file_name FROM dual;
SPOOL &&exp_file_name

SELECT 'CONCEPT_ID' || ','
    || 'CONCEPT_NAME' || ','
    || 'DOMAIN_ID' || ','
    || 'VOCABULARY_ID' || ','
    || 'CONCEPT_CLASS_ID' || ','
    || 'STANDARD_CONCEPT' || ','
    || 'CONCEPT_CODE' || ','
    || 'VALID_START_DATE' || ','
    || 'VALID_END_DATE' || ','
    || 'INVALID_REASON' FROM DUAL
UNION ALL
SELECT '"' || CONCEPT_ID  || '",'
    || '"' || CONCEPT_NAME || '",'
    || '"' || DOMAIN_ID || '",'
    || '"' || VOCABULARY_ID || '",'
    || '"' || CONCEPT_CLASS_ID || '",'
    || '"' || STANDARD_CONCEPT || '",'
    || '"' || CONCEPT_CODE || '",'
    || '"' || VALID_START_DATE || '",'
    || '"' || VALID_END_DATE || '",'
    || '"' || INVALID_REASON || '"'
FROM &3
;

SPOOL OFF
EXIT