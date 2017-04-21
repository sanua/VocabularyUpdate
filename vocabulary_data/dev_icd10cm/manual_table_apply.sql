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

PROMPT Update &2's dates...
update &2 set valid_start_date = sysdate 
where valid_start_date is null
;
commit
;
update &2 set valid_end_date = to_date ('20991231', 'yyyymmdd')
where valid_end_date is null
;
commit
;

PROMPT Empty the 'concept_relationship_manual' table...
TRUNCATE TABLE concept_relationship_manual;
COMMIT;

--need to think if we need to give only those where concept_code_2 is null or it's mappped only to deprecated concept
-- if medical coder wants to change relatoinship (i.e. found a better mapping - set an old row as deprecated, add a new row to concept_relationship)
--;
--do it once &2 is done by medical coder
--or probably another temporary table can be used where we put the result of manual mappings
--truncate table
PROMPT Need to think if we need to give only those where concept_code_2 is null or it is mappped only to deprecated concept
PROMPT if medical coder wants to change relationship (i.e. found a better mapping - set an old row as deprecated, add a new row to concept_relationship)
PROMPT do it once &2 is done by medical coder
PROMPT or probably another temporary table can be used where we put the result of manual mappings...
insert into concept_relationship_manual (CONCEPT_CODE_1,CONCEPT_CODE_2,VOCABULARY_ID_1,VOCABULARY_ID_2,RELATIONSHIP_ID,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select CONCEPT_CODE_1,CONCEPT_CODE_2,VOCABULARY_ID_1,VOCABULARY_ID_2,RELATIONSHIP_ID,VALID_START_DATE,VALID_END_DATE,INVALID_REASON from &2
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

SPOOL OFF
EXIT