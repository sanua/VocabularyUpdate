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

SELECT 'CONCEPT_CODE_1' || ','
    || 'CONCEPT_NAME_1' || ','
    || 'VOCABULARY_ID_1' || ','
    || 'INVALID_REASON_1' || ','
    || 'CONCEPT_CODE_2' || ','
    || 'CONCEPT_NAME_2' || ','
    || 'CONCEPT_CLASS_ID_2' || ','
    || 'VOCABULARY_ID_2' || ','
    || 'INVALID_REASON_2' || ','
    || 'RELATIONSHIP_ID' || ','
    || 'VALID_START_DATE' || ','
    || 'VALID_END_DATE' || ','
    || 'INVALID_REASON'
FROM DUAL
UNION ALL
SELECT '"' || CONCEPT_CODE_1  || '",'
    || '"' || CONCEPT_NAME_1 || '",'
    || '"' || VOCABULARY_ID_1 || '",'
    || '"' || INVALID_REASON_1 || '",'
    || '"' || CONCEPT_CODE_2 || '",'
    || '"' || CONCEPT_NAME_2 || '",'
    || '"' || CONCEPT_CLASS_ID_2 || '",'
    || '"' || VOCABULARY_ID_2 || '",'
    || '"' || INVALID_REASON_2 || '",'
    || '"' || RELATIONSHIP_ID || '",'
    || '"' || TO_CHAR(VALID_START_DATE, 'YYYY-MM-DD HH24:MI:SS') || '",'
    || '"' || TO_CHAR(VALID_END_DATE, 'YYYY-MM-DD HH24:MI:SS') || '",'
    || '"' || INVALID_REASON || '"'
FROM &3
;

SPOOL OFF
EXIT