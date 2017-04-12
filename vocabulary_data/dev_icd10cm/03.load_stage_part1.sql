/**************************************************************************
* Copyright 2016 Observational Health Data Sciences and Informatics (OHDSI)
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
* 
* Authors: Timur Vakhitov, Christian Reich
* Date: 2016
**************************************************************************/

SET sqlbl on
SET VERIFY OFF
/* If any errors occurs - stop script execution and return error code */
WHENEVER SQLERROR EXIT SQL.SQLCODE
/*
 *****************************
 *  Log to file...    
 *****************************
*/
SPOOL &1

/* Clean up from last unsuccessful load stage run, to avoid build process errors */
PROMPT Clean up from last unsuccessful load stage run, to avoid build process errors...
DECLARE
  TYPE TStringArray IS TABLE OF VARCHAR2(255);
  t_names TStringArray := TStringArray('ICD10CM_domain','filled_domain');
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

-- 1. Update latest_update field to new date 
PROMPT 1. Update latest_update field to new date...
BEGIN
   DEVV5.VOCABULARY_PACK.SetLatestUpdate (pVocabularyName        => 'ICD10CM',
                                          pVocabularyDate        => TO_DATE ('20160325', 'yyyymmdd'),
                                          pVocabularyVersion     => 'ICD10CM FY2016 code descriptions',
                                          pVocabularyDevSchema   => 'DEV_ICD10CM');
END;
/
COMMIT;

-- 2. Truncate all working tables
PROMPT 2. Truncate all working tables...
TRUNCATE TABLE concept_stage;
TRUNCATE TABLE concept_relationship_stage;
TRUNCATE TABLE concept_synonym_stage;
TRUNCATE TABLE pack_content_stage;
TRUNCATE TABLE drug_strength_stage;

--3. Load into concept_stage from ICD10CM_TABLE
PROMPT 3. Load into concept_stage from ICD10CM_TABLE...
INSERT /*+ APPEND */ INTO concept_stage (concept_id,
                           concept_name,
                           domain_id,
                           vocabulary_id,
                           concept_class_id,
                           standard_concept,
                           concept_code,
                           valid_start_date,
                           valid_end_date,
                           invalid_reason)
   SELECT NULL AS concept_id,
          SUBSTR (
             CASE
                WHEN LENGTH (LONG_NAME) > 255 AND SHORT_NAME IS NOT NULL
                THEN
                   SHORT_NAME
                ELSE
                   LONG_NAME
             END,
             1,
             255)
             AS concept_name,
          NULL AS domain_id,
          'ICD10CM' AS vocabulary_id,
          CASE
             WHEN CODE_TYPE = 1 THEN LENGTH (code) || '-char billing code'
             ELSE LENGTH (code) || '-char nonbill code'
          END
             AS concept_class_id,
          NULL AS standard_concept,
          REGEXP_REPLACE (code, '([[:print:]]{3})([[:print:]]+)', '\1.\2') -- Dot after 3 characters
             AS concept_code,
          (SELECT latest_update
             FROM vocabulary
            WHERE vocabulary_id = 'ICD10CM')
             AS valid_start_date,
          TO_DATE ('20991231', 'yyyymmdd') AS valid_end_date,
          NULL AS invalid_reason
     FROM ICD10CM_TABLE;
COMMIT;

-- At the end, the three tables concept_stage, concept_relationship_stage and concept_synonym_stage should be ready to be fed into the generic_update.sql script		
PROMPT At the end, the three tables concept_stage, concept_relationship_stage and concept_synonym_stage should be ready to be fed into the generic_update.sql script...

SET sqlbl off
SPOOL OFF
EXIT