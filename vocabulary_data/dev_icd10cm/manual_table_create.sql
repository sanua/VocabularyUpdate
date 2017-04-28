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

/* Delete Manual Table is exist */
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
   CONCEPT_CODE_1		  VARCHAR2(50 BYTE),
   CONCEPT_NAME_1 		VARCHAR(250),
   VOCABULARY_ID_1		VARCHAR(20), 
   INVALID_REASON_1		VARCHAR2(1 BYTE),
   CONCEPT_CODE_2		  VARCHAR2(50 BYTE),
   CONCEPT_NAME_2		  VARCHAR(250),
   CONCEPT_CLASS_ID_2	VARCHAR(250),
   VOCABULARY_ID_2		VARCHAR(20) ,
   INVALID_REASON_2		VARCHAR2(1 BYTE),
   RELATIONSHIP_ID		VARCHAR2(20 BYTE),
   VALID_START_DATE		DATE,
   VALID_END_DATE	  	DATE,
   INVALID_REASON		  VARCHAR2(1 BYTE)
)
NOLOGGING
;

-- Create file with mappings for medical coder from the existing one
-- instead of concept use concept_stage (medical coders need to review new concepts also)
-- need to add more useful attributes exactly to concept_relationship_manual to make the manual mapping process easier
-- create temporary table &2 that will be filled by the medical coder
PROMPT Create file with mappings for medical coder from the existing one
PROMPT instead of concept use concept_stage (medical coders need to review new concepts also)
PROMPT need to add more useful attributes exactly to concept_relationship_manual to make the manual mapping process easier
PROMPT create temporary table &2 that will be filled by the medical coder...
truncate table &2;
insert into &2 (CONCEPT_CODE_1,CONCEPT_NAME_1,VOCABULARY_ID_1,invalid_reason_1, CONCEPT_CODE_2,CONCEPT_NAME_2,CONCEPT_CLASS_ID_2,VOCABULARY_ID_2,invalid_reason_2, RELATIONSHIP_ID,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
SELECT c.concept_code,c.concept_name,c.vocabulary_id,c.invalid_reason, t.concept_code, t.concept_name,t.concept_class_id,t.vocabulary_id,t.invalid_reason, r.RELATIONSHIP_ID, r.VALID_START_DATE, r.VALID_END_DATE, r.INVALID_REASON
  FROM concept_stage c
  left join concept cc on c.concept_code = cc.concept_code and cc.vocabulary_id = 'ICD10CM' and cc.invalid_reason is null
 left join  concept_relationship r on cc.concept_id = r.concept_id_1 and r.relationship_id in ('Maps to', 'Maps to value') and r.invalid_reason is null -- for this case other relationships shouldn't be checked manualy
 left join concept t on t.concept_id = r.concept_id_2 and t.invalid_reason is null
;

COMMIT;

SPOOL OFF
EXIT