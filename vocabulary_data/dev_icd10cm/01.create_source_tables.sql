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

SET SERVEROUTPUT ON
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

/* Delete import-data table if it exists, to avoid build process errors */
PROMPT Delete import-data table if it exists, to avoid build process errors...
DECLARE
	TYPE TStringArray IS TABLE OF VARCHAR2(255);
	t_names TStringArray := TStringArray('ICD10CM_TABLE');
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

PROMPT Create ICD10CM_TABLE...
CREATE TABLE ICD10CM_TABLE
(
   CODE         VARCHAR2 (8),
   CODE_TYPE    NUMBER,
   SHORT_NAME   VARCHAR2 (100),
   LONG_NAME    VARCHAR2 (500)
)
NOLOGGING;

SPOOL OFF
EXIT