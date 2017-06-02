SET SERVEROUTPUT ON
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

update manual_table set valid_start_date = sysdate 
where valid_start_date is null
;
commit
;
update manual_table set valid_end_date = to_date ('20991231', 'yyyymmdd')
where valid_end_date is null
;
commit
;

--need to think if we need to give only those where concept_code_2 is null or it's mappped only to deprecated concept
-- if medical coder wants to change relatoinship (i.e. found a better mapping - set an old row as deprecated, add a new row to concept_relationship)
--;
--do it once MANUAL_table is done by medical coder
--or probably another temporary table can be used where we put the result of manual mappings
--truncate table
insert into concept_relationship_manual (CONCEPT_CODE_1,CONCEPT_CODE_2,VOCABULARY_ID_1,VOCABULARY_ID_2,RELATIONSHIP_ID,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select CONCEPT_CODE_1,CONCEPT_CODE_2,VOCABULARY_ID_1,VOCABULARY_ID_2,RELATIONSHIP_ID,VALID_START_DATE,VALID_END_DATE,INVALID_REASON from MANUAL_table
;
commit
;

/* This is WORKAROUND-HACK.TODO: should be checked later */
delete from concept_relationship_manual where (CONCEPT_CODE_1, CONCEPT_CODE_2) in 
(select CONCEPT_CODE_1, CONCEPT_CODE_2
  FROM concept_relationship_manual  crm
             LEFT JOIN concept c1 ON c1.concept_code = crm.concept_code_1 AND c1.vocabulary_id = crm.vocabulary_id_1
             LEFT JOIN concept_stage cs1 ON cs1.concept_code = crm.concept_code_1 AND cs1.vocabulary_id = crm.vocabulary_id_1
             LEFT JOIN concept c2 ON c2.concept_code = crm.concept_code_2 AND c2.vocabulary_id = crm.vocabulary_id_2
             LEFT JOIN concept_stage cs2 ON cs2.concept_code = crm.concept_code_2 AND cs2.vocabulary_id = crm.vocabulary_id_2
             LEFT JOIN vocabulary v1 ON v1.vocabulary_id = crm.vocabulary_id_1
             LEFT JOIN vocabulary v2 ON v2.vocabulary_id = crm.vocabulary_id_2
             LEFT JOIN relationship rl ON rl.relationship_id = crm.relationship_id
       WHERE    (c1.concept_code IS NULL AND cs1.concept_code IS NULL)
             OR (c2.concept_code IS NULL AND cs2.concept_code IS NULL)
             OR v1.vocabulary_id IS NULL
             OR v2.vocabulary_id IS NULL
             OR rl.relationship_id IS NULL
             OR crm.valid_start_date > SYSDATE
             OR crm.valid_end_date < crm.valid_start_date
             OR (crm.invalid_reason IS NULL AND crm.valid_end_date <> TO_DATE ('20991231', 'yyyymmdd')));
COMMIT;
/*End of WORKAROUND-HACK*/

--4 Add ICD10CM to SNOMED manual mappings
BEGIN
   DEVV5.VOCABULARY_PACK.ProcessManualRelationships;
END;
/
COMMIT;

--5 Working with replacement mappings
BEGIN
   DEVV5.VOCABULARY_PACK.CheckReplacementMappings;
END;
/
COMMIT;

--6 Deprecate 'Maps to' mappings to deprecated and upgraded concepts
BEGIN
   DEVV5.VOCABULARY_PACK.DeprecateWrongMAPSTO;
END;
/
COMMIT;		

--7 Add mapping from deprecated to fresh concepts
BEGIN
   DEVV5.VOCABULARY_PACK.AddFreshMAPSTO;
END;
/
COMMIT;

--8 Delete ambiguous 'Maps to' mappings
BEGIN
   DEVV5.VOCABULARY_PACK.DeleteAmbiguousMAPSTO;
END;
/
COMMIT;


--9 Add "subsumes" relationship between concepts where the concept_code is like of another
INSERT INTO concept_relationship_stage (concept_code_1,
                                        concept_code_2,
                                        vocabulary_id_1,
                                        vocabulary_id_2,
                                        relationship_id,
                                        valid_start_date,
                                        valid_end_date,
                                        invalid_reason)
   SELECT c1.concept_code AS concept_code_1,
          c2.concept_code AS concept_code_2,
          c1.vocabulary_id AS vocabulary_id_1,
          c1.vocabulary_id AS vocabulary_id_2,
          'Subsumes' AS relationship_id,
          (SELECT latest_update
             FROM vocabulary
            WHERE vocabulary_id = c1.vocabulary_id)
             AS valid_start_date,
          TO_DATE ('20991231', 'yyyymmdd') AS valid_end_date,
          NULL AS invalid_reason
     FROM concept_stage c1, concept_stage c2
    WHERE     c2.concept_code LIKE c1.concept_code || '%'
          AND c1.concept_code <> c2.concept_code
          AND NOT EXISTS
                 (SELECT 1
                    FROM concept_relationship_stage r_int
                   WHERE     r_int.concept_code_1 = c1.concept_code
                         AND r_int.concept_code_2 = c2.concept_code
                         AND r_int.relationship_id = 'Subsumes');
COMMIT;

--10 Update domain_id for ICD10CM from SNOMED
--create 1st temporary table ICD10CM_domain with direct mappings
create table filled_domain NOLOGGING as
	with domain_map2value as (--ICD10CM have direct "Maps to value" mapping
		SELECT c1.concept_code, c2.domain_id
		FROM concept_relationship_stage r, concept_stage c1, concept c2
		WHERE c1.concept_code=r.concept_code_1 AND c2.concept_code=r.concept_code_2
		AND c1.vocabulary_id=r.vocabulary_id_1 AND c2.vocabulary_id=r.vocabulary_id_2
		AND r.vocabulary_id_1='ICD10CM' AND r.vocabulary_id_2='SNOMED'
		AND r.relationship_id='Maps to value'
		AND r.invalid_reason is null
	)
	select 
	d.concept_code,
	--some rules for domain_id
	case    when d.domain_id in ('Procedure', 'Measurement') 
				and exists (select 1 from domain_map2value t where t.concept_code=d.concept_code and t.domain_id in ('Meas Value' , 'Spec Disease Status'))
				then 'Measurement'
			when d.domain_id = 'Procedure' and exists (select 1 from domain_map2value t where t.concept_code=d.concept_code and t.domain_id = 'Condition')
				then 'Condition'
			when d.domain_id = 'Condition' and exists (select 1 from domain_map2value t where t.concept_code=d.concept_code and t.domain_id = 'Procedure')
				then 'Condition' 
			when d.domain_id = 'Observation' 
				then 'Observation'                 
			else d.domain_id
	end domain_id
	FROM --simplify domain_id
	( select concept_code,
		case when domain_id='Condition/Measurement' then 'Condition'
			 when domain_id='Condition/Procedure' then 'Condition'
			 when domain_id='Condition/Observation' then 'Observation'
			 when domain_id='Observation/Procedure' then 'Observation'
			 when domain_id='Measurement/Observation' then 'Observation'
			 when domain_id='Measurement/Procedure' then 'Measurement'
			 else domain_id
		end domain_id
		from ( --ICD10CM have direct "Maps to" mapping
			select concept_code, listagg(domain_id,'/') within group (order by domain_id) domain_id from (
				SELECT distinct c1.concept_code, c2.domain_id
				FROM concept_relationship_stage r, concept_stage c1, concept c2
				WHERE c1.concept_code=r.concept_code_1 AND c2.concept_code=r.concept_code_2
				AND c1.vocabulary_id=r.vocabulary_id_1 AND c2.vocabulary_id=r.vocabulary_id_2
				AND r.vocabulary_id_1='ICD10CM' AND r.vocabulary_id_2='SNOMED'
				AND r.relationship_id='Maps to'
				AND r.invalid_reason is null
			)
			group by concept_code
		)
	) d;

--create 2d temporary table with ALL ICD10CM domains
--if domain_id is empty we use previous and next domain_id or its combination
create table ICD10CM_domain NOLOGGING as
    select concept_code, 
    case when domain_id is not null then domain_id 
    else 
        case when prev_domain=next_domain then prev_domain --prev and next domain are the same (and of course not null both)
            when prev_domain is not null and next_domain is not null then  
                case when prev_domain<next_domain then prev_domain||'/'||next_domain 
                else next_domain||'/'||prev_domain 
                end -- prev and next domain are not same and not null both, with order by name
            else coalesce (prev_domain,next_domain,'Unknown')
        end
    end domain_id
    from (
            select concept_code, LISTAGG(domain_id, '/') WITHIN GROUP (order by domain_id) domain_id, prev_domain, next_domain from (

                        select distinct c1.concept_code, r1.domain_id,
                            (select MAX(fd.domain_id) KEEP (DENSE_RANK LAST ORDER BY fd.concept_code) from filled_domain fd where fd.concept_code<c1.concept_code and r1.domain_id is null) prev_domain,
                            (select MIN(fd.domain_id) KEEP (DENSE_RANK FIRST ORDER BY fd.concept_code) from filled_domain fd where fd.concept_code>c1.concept_code and r1.domain_id is null) next_domain
                        from concept_stage c1
                        left join filled_domain r1 on r1.concept_code=c1.concept_code
                        where c1.vocabulary_id='ICD10CM'
            )
            group by concept_code,prev_domain, next_domain
    );

-- INDEX was set as UNIQUE to prevent concept_code duplication
CREATE UNIQUE INDEX idx_ICD10CM_domain ON ICD10CM_domain (concept_code) NOLOGGING;

--11 Simplify the list by removing Observations
update ICD10CM_domain set domain_id=trim('/' FROM replace('/'||domain_id||'/','/Observation/','/'))
where '/'||domain_id||'/' like '%/Observation/%'
and instr(domain_id,'/')<>0;

--Reducing some domain_id if his length>20
update ICD10CM_domain set domain_id='Condition/Meas' where domain_id='Condition/Measurement';

COMMIT;

-- Check that all domain_id are exists in domain table
ALTER TABLE ICD10CM_domain ADD CONSTRAINT fk_ICD10CM_domain FOREIGN KEY (domain_id) REFERENCES domain (domain_id);

--12 Update each domain_id with the domains field from ICD10CM_domain.
UPDATE concept_stage c
   SET (domain_id) =
          (SELECT domain_id
             FROM ICD10CM_domain rd
            WHERE rd.concept_code = c.concept_code)
 WHERE c.vocabulary_id = 'ICD10CM';
COMMIT;

--13 Load into concept_synonym_stage name from ICD10CM_TABLE
INSERT /*+ APPEND */ INTO concept_synonym_stage (synonym_concept_id,
                                   synonym_concept_code,
                                   synonym_name,
                                   synonym_vocabulary_id,
                                   language_concept_id)
   SELECT DISTINCT NULL AS synonym_concept_id,
                   code AS synonym_concept_code,
                   DESCRIPTION AS synonym_name,
                   'ICD10CM' AS synonym_vocabulary_id,
                   4180186 AS language_concept_id                   -- English
     FROM (SELECT LONG_NAME,
                  SHORT_NAME,
                  REGEXP_REPLACE (code,
                                  '([[:print:]]{3})([[:print:]]+)',
                                  '\1.\2')
                     AS code
             FROM ICD10CM_TABLE) UNPIVOT (DESCRIPTION --take both LONG_NAME and SHORT_NAME
                                 FOR DESCRIPTIONS
                                 IN (LONG_NAME, SHORT_NAME));
COMMIT;

--14 Clean up
DROP TABLE ICD10CM_domain PURGE;
DROP TABLE filled_domain PURGE;	

SET sqlbl off
-- At the end, the three tables concept_stage, concept_relationship_stage and concept_synonym_stage should be ready to be fed into the generic_update.sql script		

SPOOL OFF
EXIT