SET SERVEROUTPUT ON
SET ECHO OFF
SET sqlbl on
SET VERIFY OFF
/* If any errors occurs - stop script execution and return error code */
WHENEVER SQLERROR EXIT SQL.SQLCODE
/*
 *****************************
 *  Log to file...    
 *****************************
*/
SPOOL '&1'

--8 Run the generic working/MapDrugVocabulary.sql. This will produce a concept_relationship_stage with HCPCS to RxNorm relatoinships
PROMPT ***
PROMPT * 8 Run the generic working/MapDrugVocabulary.sql. This will produce a concept_relationship_stage with HCPCS to RxNorm relatoinships
PROMPT ***
@&2/MapDrugVocabulary.sql '&3'
PROMPT ***
PROMPT * 8 Run the generic working/MapDrugVocabulary.sql is done...
PROMPT ***

--9 Add all other relationships from the existing one. The reason is that there is no good source for these relationships, and we have to build the ones for new codes from UMLS and manually
PROMPT 9 Add all other relationships from the existing one. The reason is that there is no good source for these relationships, and we have to build the ones for new codes from UMLS and manually
INSERT /*+ APPEND */ INTO concept_relationship_stage (concept_id_1,
                                        concept_id_2,
                                        concept_code_1,
                                        concept_code_2,
                                        relationship_id,
                                        vocabulary_id_1,
                                        vocabulary_id_2,
                                        valid_start_date,
                                        valid_end_date,
                                        invalid_reason)
   SELECT NULL AS concept_id_1,
          NULL AS concept_id_2,
          c.concept_code AS concept_code_1,
          c1.concept_code AS concept_code_2,
          r.relationship_id AS relationship_id,
          c.vocabulary_id AS vocabulary_id_1,
          c1.vocabulary_id AS vocabulary_id_2,
          r.valid_start_date,
          r.valid_end_date,
          r.invalid_reason
     FROM concept_relationship r, concept c, concept c1
    WHERE     c.concept_id = r.concept_id_1
          AND c.vocabulary_id = 'HCPCS'
          AND c1.concept_id = r.concept_id_2
		  AND r.relationship_id NOT IN ('Concept replaced by','Is a') --we add it below
		  AND NOT (c1.vocabulary_id='RxNorm' AND r.relationship_id='Maps to'); 
COMMIT;

--10 Add upgrade relationships
PROMPT 10 Add upgrade relationships
INSERT /*+ APPEND */ INTO  concept_relationship_stage (concept_code_1,
                                        concept_code_2,
                                        relationship_id,
                                        vocabulary_id_1,
                                        vocabulary_id_2,
                                        valid_start_date,
                                        valid_end_date,
                                        invalid_reason)
   SELECT DISTINCT concept_code_1,
                   concept_code_2,
                   'Concept replaced by' AS relationship_id,
                   'HCPCS' AS vocabulary_id_1,
                   'HCPCS' AS vocabulary_id_2,
                   valid_start_date,
                   valid_end_date,
                   NULL AS invalid_reason
     FROM (SELECT A.HCPC AS concept_code_1,
                  A.XREF1 AS concept_code_2,
                  COALESCE (A.ADD_DATE, A.ACT_EFF_DT) AS valid_start_date,
                  TO_DATE ('20991231', 'yyyymmdd') AS valid_end_date
             FROM ANWEB_V2 a, ANWEB_V2 b
            WHERE A.XREF1 = B.HCPC AND A.TERM_DT IS NOT NULL AND B.TERM_DT IS NULL
           UNION ALL
           SELECT A.HCPC AS concept_code_1,
                  A.XREF2,
                  COALESCE (A.ADD_DATE, A.ACT_EFF_DT),
                  TO_DATE ('20991231', 'yyyymmdd')
             FROM ANWEB_V2 a, ANWEB_V2 b
            WHERE A.XREF2 = B.HCPC AND A.TERM_DT IS NOT NULL AND B.TERM_DT IS NULL
           UNION ALL
           SELECT A.HCPC AS concept_code_1,
                  A.XREF3,
                  COALESCE (A.ADD_DATE, A.ACT_EFF_DT),
                  TO_DATE ('20991231', 'yyyymmdd')
             FROM ANWEB_V2 a, ANWEB_V2 b
            WHERE A.XREF3 = B.HCPC AND A.TERM_DT IS NOT NULL AND B.TERM_DT IS NULL
           UNION ALL
           SELECT A.HCPC AS concept_code_1,
                  A.XREF4,
                  COALESCE (A.ADD_DATE, A.ACT_EFF_DT),
                  TO_DATE ('20991231', 'yyyymmdd')
             FROM ANWEB_V2 a, ANWEB_V2 b
            WHERE A.XREF4 = B.HCPC AND A.TERM_DT IS NOT NULL AND B.TERM_DT IS NULL
           UNION ALL
           SELECT A.HCPC AS concept_code_1,
                  A.XREF5,
                  COALESCE (A.ADD_DATE, A.ACT_EFF_DT),
                  TO_DATE ('20991231', 'yyyymmdd')
             FROM ANWEB_V2 a, ANWEB_V2 b
            WHERE A.XREF5 = B.HCPC AND A.TERM_DT IS NOT NULL AND B.TERM_DT IS NULL) i
    WHERE NOT EXISTS
             (SELECT 1
                FROM concept_relationship_stage crs_int
               WHERE     crs_int.concept_code_1 = i.concept_code_1
                     AND crs_int.concept_code_2 = i.concept_code_2
                     AND crs_int.vocabulary_id_1 = 'HCPCS'
                     AND crs_int.vocabulary_id_2 = 'HCPCS'
                     AND crs_int.relationship_id = 'Concept replaced by');
COMMIT;		  

--11 Working with replacement mappings
PROMPT 11 Working with replacement mappings
BEGIN
   DEVV5.VOCABULARY_PACK.CheckReplacementMappings;
END;
/
COMMIT;

--12 Deprecate 'Maps to' mappings to deprecated and upgraded concepts
PROMPT 12 Deprecate 'Maps to' mappings to deprecated and upgraded concepts
BEGIN
   DEVV5.VOCABULARY_PACK.DeprecateWrongMAPSTO;
END;
/
COMMIT;			

--13 Create hierarchical relationships between HCPCS and HCPCS class
PROMPT 13 Create hierarchical relationships between HCPCS and HCPCS class
INSERT /*+ APPEND */ INTO concept_relationship_stage (
                                        concept_code_1,
                                        concept_code_2,
                                        relationship_id,
                                        vocabulary_id_1,
                                        vocabulary_id_2,
                                        valid_start_date,
                                        valid_end_date,
                                        invalid_reason)
   SELECT DISTINCT
          A.HCPC AS concept_code_1,
          A.BETOS AS concept_code_2,
          'Is a' AS relationship_id,
          'HCPCS' AS vocabulary_id_1,
          'HCPCS' AS vocabulary_id_2,
          COALESCE (A.ADD_DATE, A.ACT_EFF_DT) AS valid_start_date,
          COALESCE (A.TERM_DT, TO_DATE ('20991231', 'yyyymmdd'))
             AS valid_end_date,
          CASE
             WHEN TERM_DT IS NULL THEN NULL
             WHEN XREF1 IS NULL THEN 'D'                         -- deprecated
             ELSE NULL                                             -- upgraded
          END
             AS invalid_reason
     FROM ANWEB_V2 a
    JOIN concept c
          ON     c.concept_code = A.BETOS
             AND c.concept_class_id = 'HCPCS Class'
             AND c.VOCABULARY_ID = 'HCPCS'
			 AND c.invalid_reason IS NULL; 
COMMIT;	

--14 Add all other 'Concept replaced by' relationships
PROMPT 14 Add all other 'Concept replaced by' relationships
INSERT /*+ APPEND */ INTO  concept_relationship_stage (concept_code_1,
                                        concept_code_2,
                                        relationship_id,
                                        vocabulary_id_1,
                                        vocabulary_id_2,
                                        valid_start_date,
                                        valid_end_date,
                                        invalid_reason)
   SELECT c.concept_code AS concept_code_1,
          c1.concept_code AS concept_code_2,
          r.relationship_id AS relationship_id,
          c.vocabulary_id AS vocabulary_id_1,
          c1.vocabulary_id AS vocabulary_id_2,
          r.valid_start_date,
          r.valid_end_date,
          r.invalid_reason
     FROM concept_relationship r, concept c, concept c1
    WHERE     c.concept_id = r.concept_id_1
          AND c.vocabulary_id = 'HCPCS'
          AND c1.concept_id = r.concept_id_2
          AND r.relationship_id IN ('Concept replaced by',
                                    'Concept same_as to',
                                    'Concept alt_to to',
                                    'Concept poss_eq to',
                                    'Concept was_a to')
          AND r.invalid_reason IS NULL
          AND (SELECT COUNT (*)
                 FROM concept_relationship r_int
                WHERE     r_int.concept_id_1 = r.concept_id_1
                      AND r_int.relationship_id = r.relationship_id
                      AND r_int.invalid_reason IS NULL) = 1
          AND NOT EXISTS
                 (SELECT 1
                    FROM concept_relationship_stage crs
                   WHERE     crs.concept_code_1 = c.concept_code
                         AND crs.vocabulary_id_1 = c.vocabulary_id
                         AND crs.relationship_id = r.relationship_id);
COMMIT;

PROMPT 15 "Manual Table" processing is skipped...
/* Skip this section...
This is a subject of "Manual Table" creation

--15 Create text for Medical Coder with new codes and mappings
PROMPT  15 Create text for Medical Coder with new codes and mappings
SELECT NULL AS concept_id_1,
       NULL AS concept_id_2,
       c.concept_code AS concept_code_1,
       u2.scui AS concept_code_2,
       CASE
          WHEN c.domain_id = 'Procedure' THEN 'HCPCS - SNOMED proc'
          WHEN c.domain_id = 'Measurement' THEN 'HCPCS - SNOMED meas'
          ELSE 'HCPCS - SNOMED obs'
       END
          AS relationship_id, -- till here strawman for concept_relationship to be checked and filled out, the remaining are supportive information to be truncated in the return file
       c.concept_name AS cpt_name,
       u2.str AS snomed_str,
       sno.concept_id AS snomed_concept_id,
       sno.concept_name AS snomed_name
  FROM concept_stage c
       LEFT JOIN
       (                                         -- UMLS record for HCPCS code
        SELECT DISTINCT cui, scui
          FROM UMLS.mrconso
         WHERE sab IN ('HCPCS') AND suppress NOT IN ('E', 'O', 'Y')) u1
          ON u1.scui = concept_code                  -- join UMLS for code one
       LEFT JOIN
       (                        -- UMLS record for SNOMED code of the same cui
        SELECT DISTINCT
               cui,
               scui,
               FIRST_VALUE (
                  str)
               OVER (PARTITION BY scui
                     ORDER BY DECODE (tty,  'PT', 1,  'PTGB', 2,  10))
                  AS str
          FROM UMLS.mrconso
         WHERE sab IN ('SNOMEDCT_US') AND suppress NOT IN ('E', 'O', 'Y')) u2
          ON u2.cui = u1.cui
       LEFT JOIN concept sno
          ON sno.vocabulary_id = 'SNOMED' AND sno.concept_code = u2.scui -- SNOMED concept
 WHERE     NOT EXISTS
              (                        -- only new codes we don't already have
               SELECT 1
                 FROM concept co
                WHERE     co.concept_code = c.concept_code
                      AND co.vocabulary_id = 'HCPCS')
       AND c.vocabulary_id = 'HCPCS'
       AND c.concept_class_id IN ('HCPCS', 'HCPCS Modifier');

end of skipping */

--16 Append resulting file from Medical Coder (in concept_relationship_stage format) to concept_relationship_stage
PROMPT 16 Append resulting file from Medical Coder (in concept_relationship_stage format) to concept_relationship_stage
BEGIN
   DEVV5.VOCABULARY_PACK.ProcessManualRelationships;
END;
/
COMMIT;

--17 Add mapping from deprecated to fresh concepts
PROMPT 17 Add mapping from deprecated to fresh concepts
BEGIN
   DEVV5.VOCABULARY_PACK.AddFreshMAPSTO;
END;
/
COMMIT;	   

--18 Delete ambiguous 'Maps to' mappings
PROMPT 18 Delete ambiguous 'Maps to' mappings
BEGIN
   DEVV5.VOCABULARY_PACK.DeleteAmbiguousMAPSTO;
END;
/
COMMIT;		 

--19 All the codes that have mapping to RxNorm should get domain_id='Drug'
PROMPT 19 All the codes that have mapping to RxNorm should get domain_id='Drug'
UPDATE concept_stage cs
   SET cs.domain_id='Drug'
 WHERE     EXISTS
-- existing in concept_relationship
              (SELECT 1
                 FROM concept_relationship r, concept c1, concept c2
                WHERE     r.concept_id_1 = c1.concept_id
                      AND r.concept_id_2 = c2.concept_id
                      AND r.invalid_reason IS NULL
                      AND r.relationship_id = 'Maps to'
                      AND c2.vocabulary_id = 'RxNorm'
                      AND c1.concept_code = cs.concept_code
                      AND c1.vocabulary_id = cs.vocabulary_id
               UNION ALL
-- new in concept_relationship_stage
               SELECT 1
                 FROM concept_relationship_stage r
                WHERE     r.concept_code_1 = cs.concept_code
                      AND r.vocabulary_id_1 = cs.vocabulary_id
                      AND r.invalid_reason IS NULL
                      AND r.relationship_id = 'Maps to'
                      AND r.vocabulary_id_2 = 'RxNorm')
       AND cs.domain_id<>'Drug';
COMMIT;

--20 Procedure Drugs who have a mapping to a Drug concept should not also be recorded as Procedures (no Standard Concepts)
PROMPT 20 Procedure Drugs who have a mapping to a Drug concept should not also be recorded as Procedures (no Standard Concepts)
UPDATE concept_stage cs
   SET cs.standard_concept = NULL
 WHERE     EXISTS
              (SELECT 1
                 FROM concept_relationship r, concept c1, concept c2
                WHERE     r.concept_id_1 = c1.concept_id
                      AND r.concept_id_2 = c2.concept_id
                      AND r.invalid_reason IS NULL
                      AND r.relationship_id = 'Maps to'
                      AND c2.domain_id = 'Drug'
                      AND c1.concept_code = cs.concept_code
                      AND c1.vocabulary_id = cs.vocabulary_id
               UNION ALL
               SELECT 1
                 FROM concept_relationship_stage r, concept c2
                WHERE     r.concept_code_1 = cs.concept_code
                      AND r.vocabulary_id_1 = cs.vocabulary_id
                      AND r.concept_code_2 = c2.concept_code
                      AND r.vocabulary_id_2 = c2.vocabulary_id
                      AND r.invalid_reason IS NULL
                      AND r.relationship_id = 'Maps to'
                      AND c2.domain_id = 'Drug')
       AND cs.standard_concept IS NOT NULL;
COMMIT;

-- At the end, the three tables concept_stage, concept_relationship_stage and concept_synonym_stage should be ready to be fed into the generic_update.sql script
PROMPT At the end, the three tables concept_stage, concept_relationship_stage and concept_synonym_stage should be ready to be fed into the generic_update.sql script

SET sqlbl off
SPOOL OFF
EXIT