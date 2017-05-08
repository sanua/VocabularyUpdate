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

/* Delete '&2' if exist */
PROMPT Delete '&2' if exist...
DECLARE
	TYPE TStringArray IS TABLE OF VARCHAR2(255);
	t_names TStringArray := TStringArray('&2');
	l_cnt NUMBER;
	l_str VARCHAR2(255);
BEGIN
	FOR i in t_names.FIRST..t_names.LAST LOOP
	  l_str := t_names(i);
    SELECT COUNT(1) INTO l_cnt FROM user_tables WHERE UPPER(table_name) = UPPER(l_str);
    IF l_cnt > 0 THEN
      EXECUTE IMMEDIATE 'DROP TABLE ' || l_str;
    END IF;
	END LOOP;
END;
/

PROMPT Create &2...
CREATE TABLE &2 
(
	CONCEPT_CODE_1		VARCHAR2(255),
	CONCEPT_NAME_1      VARCHAR2(255),
	CONCEPT_ID_2		NUMBER(38),
	CONCEPT_NAME_2		VARCHAR2(255),
	DOMAIN_ID			VARCHAR2(20),
	VOCABULARY_ID		VARCHAR2(20),
	INVALID_REASON		VARCHAR2(1),
	VALID_START_DATE	DATE,
	VALID_END_DATE		DATE,
	PRECEDENCE			NUMBER(38),
	CONVERSION_FACTOR	FLOAT(126)
)
NOLOGGING
;

PROMPT Create '&2' from RELATIONSHIP_TO_CONCEPT table...
-- truncate table &2;
INSERT INTO &2 (CONCEPT_CODE_1,
                CONCEPT_NAME_1,
                CONCEPT_ID_2,
                CONCEPT_NAME_2,
                DOMAIN_ID,
                VOCABULARY_ID,
                INVALID_REASON,
                VALID_START_DATE,
                VALID_END_DATE,
                PRECEDENCE,
                CONVERSION_FACTOR)
  SELECT DISTINCT 
         r2c.CONCEPT_CODE_1, 
         c1.CONCEPT_NAME AS CONCEPT_NAME_1, 
         r2c.CONCEPT_ID_2, 
         c2.CONCEPT_NAME AS CONCEPT_NAME_2, 
         c2.DOMAIN_ID, 
         c2.VOCABULARY_ID, 
         c2.INVALID_REASON, 
         c2.VALID_START_DATE, 
         c2.VALID_END_DATE, 
         r2c.PRECEDENCE, 
         r2c.CONVERSION_FACTOR 
  FROM RELATIONSHIP_TO_CONCEPT r2c
    LEFT JOIN CONCEPT c1 ON r2c.CONCEPT_CODE_1 = c1.CONCEPT_CODE AND r2c.CONCEPT_ID_2 = c1.CONCEPT_ID
    LEFT JOIN CONCEPT c2 ON r2c.CONCEPT_ID_2 = c2.CONCEPT_ID
  ORDER BY r2c.CONCEPT_CODE_1, r2c.CONCEPT_ID_2;

COMMIT;

SPOOL OFF
EXIT