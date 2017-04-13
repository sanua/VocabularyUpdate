SET VERIFY OFF
/* If any errors occurs - stop script execution and return error code */
WHENEVER SQLERROR EXIT SQL.SQLCODE
/*
 *****************************
 *  Log to file...    
 *****************************
*/
SPOOL &1

PROMPT
PROMPT 'Load Stage part 2' is starting...
EXEC DBMS_LOCK.sleep(1);

PROMPT *** Step 'procedure_drug.sql' is started... ***
-- Run HCPCS/procedure_drug.sql. This will create all the input files for MapDrugVocabulary.sql
@&2/mock/mock_procedure_drug.sql '&3'
PROMPT *** Step 'procedure_drug.sql' is done... ***

PROMPT

PROMPT *** Step 'MapDrugVocabulary.sql' is started... ***
--Run the generic working/MapDrugVocabulary.sql. This will produce a concept_relationship_stage with HCPCS to RxNorm relatoinships
@&2/mock/mock_MapDrugVocabulary.sql '&4'
prompt *** Step 'MapDrugVocabulary.sql' is done... ***

EXEC DBMS_LOCK.sleep(1);
PROMPT 'Load Stage part 2' is done...
PROMPT

SPOOL OFF
EXIT