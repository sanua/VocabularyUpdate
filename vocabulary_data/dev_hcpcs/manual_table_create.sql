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
	LABEL_TEXT       	VARCHAR2(50),
	CONCEPT_CODE_1		VARCHAR2(255),
	CONCEPT_NAME_1      VARCHAR2(255),
	CONCEPT_ID_2		NUMBER(38),
	CONCEPT_NAME_2		VARCHAR2(255),
	DOMAIN_ID			VARCHAR2(20),
	VOCABULARY_ID		VARCHAR2(20),
	CONCEPT_CLASS_ID    VARCHAR2(20),
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
INSERT INTO &2 (LABEL_TEXT,
		CONCEPT_CODE_1,
                CONCEPT_NAME_1,
                CONCEPT_ID_2,
                CONCEPT_NAME_2,
                DOMAIN_ID,
                VOCABULARY_ID,
                CONCEPT_CLASS_ID,
                INVALID_REASON,
                VALID_START_DATE,
                VALID_END_DATE,
                PRECEDENCE,
                CONVERSION_FACTOR)
  SELECT * FROM (
    WITH dcsv AS (
          SELECT 
           dcs_in.CONCEPT_CODE,
           dcs_in.CONCEPT_NAME,
           dcs_in.DOMAIN_ID,
           dcs_in.VOCABULARY_ID,
           dcs_in.CONCEPT_CLASS_ID,
           dcs_in.VALID_START_DATE,
           dcs_in.VALID_END_DATE,
           dcs_in.INVALID_REASON
      FROM DRUG_CONCEPT_STAGE dcs_in
      WHERE dcs_in.CONCEPT_CLASS_ID IN ('Brand Name','Ingredient','Dose Form','Supplier') 
      ORDER BY dcs_in.CONCEPT_CODE
    ), r2cv AS (
        SELECT 
          r2c_in.CONCEPT_CODE_1,
          r2c_in.PRECEDENCE, 
          r2c_in.CONVERSION_FACTOR,
          c2.CONCEPT_ID as CONCEPT_ID_2,
          c2.CONCEPT_NAME as CONCEPT_NAME_2,
          c2.DOMAIN_ID,
          c2.VOCABULARY_ID,
          c2.CONCEPT_CLASS_ID,
          c2.VALID_START_DATE,
          c2.VALID_END_DATE,
          c2.INVALID_REASON
        FROM RELATIONSHIP_TO_CONCEPT r2c_in
          LEFT JOIN CONCEPT c2 ON DECODE(c2.CONCEPT_ID, r2c_in.CONCEPT_ID_2, 1, 0) = 1
        ORDER BY r2c_in.CONCEPT_CODE_1, r2c_in.CONCEPT_ID_2
    )
    SELECT DISTINCT 
          'From DCS' AS LABEL_TEXT,
           dcsv.CONCEPT_CODE AS CONCEPT_CODE_1,
           dcsv.CONCEPT_NAME AS CONCEPT_NAME_1, 
           r2cv.CONCEPT_ID_2, 
           r2cv.CONCEPT_NAME_2,
           dcsv.DOMAIN_ID,
           dcsv.VOCABULARY_ID,
           dcsv.CONCEPT_CLASS_ID,
           dcsv.INVALID_REASON,
           dcsv.VALID_START_DATE,
           dcsv.VALID_END_DATE,
           r2cv.PRECEDENCE, 
           r2cv.CONVERSION_FACTOR
    FROM dcsv 
      LEFT JOIN r2cv ON DECODE(dcsv.CONCEPT_CODE, r2cv.CONCEPT_CODE_1, 1, 0) = 1        
      WHERE r2cv.CONCEPT_CODE_1 IS NULL
    UNION ALL
    SELECT DISTINCT
           'From R2C' AS LABEL_TEXT,
           r2cv.CONCEPT_CODE_1,
           dcsv.CONCEPT_NAME AS CONCEPT_NAME_1, 
           r2cv.CONCEPT_ID_2, 
           r2cv.CONCEPT_NAME_2,
           r2cv.DOMAIN_ID,
           r2cv.VOCABULARY_ID,
           r2cv.CONCEPT_CLASS_ID,
           r2cv.INVALID_REASON,
           r2cv.VALID_START_DATE,
           r2cv.VALID_END_DATE,
           r2cv.PRECEDENCE, 
           r2cv.CONVERSION_FACTOR
    FROM dcsv 
      RIGHT JOIN r2cv ON DECODE(dcsv.CONCEPT_CODE, r2cv.CONCEPT_CODE_1, 1, 0) = 1        
      --WHERE dcsv.CONCEPT_CODE IS NULL 
  ) ORDER BY LABEL_TEXT, CONCEPT_CODE_1, CONCEPT_ID_2;

COMMIT;

SPOOL OFF
EXIT