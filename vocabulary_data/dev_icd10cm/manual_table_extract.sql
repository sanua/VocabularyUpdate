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

WITH mt AS (SELECT CONCEPT_CODE_1,
                   CONCEPT_NAME_1,
                   VOCABULARY_ID_1,
                   INVALID_REASON_1,
                   CONCEPT_CODE_2,
                   CONCEPT_NAME_2,
                   CONCEPT_CLASS_ID_2,
                   VOCABULARY_ID_2,
                   INVALID_REASON_2,
                   RELATIONSHIP_ID ,
                   TO_CHAR(VALID_START_DATE, 'YYYY-MM-DD HH24:MI:SS') AS VALID_START_DATE,
                   TO_CHAR(VALID_END_DATE, 'YYYY-MM-DD HH24:MI:SS') AS VALID_END_DATE,
                   INVALID_REASON
            FROM &3
            ORDER BY CONCEPT_CODE_1, CONCEPT_NAME_1, VOCABULARY_ID_1, CONCEPT_CODE_2, CONCEPT_NAME_2, CONCEPT_CLASS_ID_2, VOCABULARY_ID_2, VALID_START_DATE, VALID_END_DATE)
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
    || 'INVALID_REASON' AS "&3 DATA"
FROM DUAL
UNION ALL
SELECT '"' || mt.CONCEPT_CODE_1  || '",'
    || '"' || mt.CONCEPT_NAME_1 || '",'
    || '"' || mt.VOCABULARY_ID_1 || '",'
    || '"' || mt.INVALID_REASON_1 || '",'
    || '"' || mt.CONCEPT_CODE_2 || '",'
    || '"' || mt.CONCEPT_NAME_2 || '",'
    || '"' || mt.CONCEPT_CLASS_ID_2 || '",'
    || '"' || mt.VOCABULARY_ID_2 || '",'
    || '"' || mt.INVALID_REASON_2 || '",'
    || '"' || mt.RELATIONSHIP_ID || '",'
    || '"' || mt.VALID_START_DATE || '",'
    || '"' || mt.VALID_END_DATE || '",'
    || '"' || mt.INVALID_REASON || '"'
FROM mt
;

SPOOL OFF
EXIT