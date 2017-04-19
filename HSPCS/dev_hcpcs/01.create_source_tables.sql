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

SET ECHO OFF
SET VERIFY OFF
/* If any errors occurs - stop script execution and return error code */
WHENEVER SQLERROR EXIT SQL.SQLCODE
/*
 *****************************
 *  Log to file...    
 *****************************
*/
SPOOL &1

/* Delete import-data table if it exists, to avoid build process errors */
PROMPT Delete import-data table if it exists, to avoid build process errors...
DECLARE
	TYPE TStringArray IS TABLE OF VARCHAR2(255);
	t_names TStringArray := TStringArray('ANWEB_V2');
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

PROMPT Create ANWEB_V2...
CREATE TABLE ANWEB_V2
(
   HCPC                VARCHAR2 (1000 CHAR),
   LONG_DESCRIPTION    VARCHAR2 (4000 CHAR),
   SHORT_DESCRIPTION   VARCHAR2 (1000 CHAR),
   PRICE_CD1           VARCHAR2 (1000 CHAR),
   PRICE_CD2           VARCHAR2 (1000 CHAR),
   PRICE_CD3           VARCHAR2 (1000 CHAR),
   PRICE_CD4           VARCHAR2 (1000 CHAR),
   MULTI_PI            VARCHAR2 (1000 CHAR),
   CIM1                VARCHAR2 (1000 CHAR),
   CIM2                VARCHAR2 (1000 CHAR),
   CIM3                VARCHAR2 (1000 CHAR),
   MCM1                VARCHAR2 (1000 CHAR),
   MCM2                VARCHAR2 (1000 CHAR),
   MCM3                VARCHAR2 (1000 CHAR),
   STATUTE             VARCHAR2 (1000 CHAR),
   LAB_CERT_CD1        VARCHAR2 (1000 CHAR),
   LAB_CERT_CD2        VARCHAR2 (1000 CHAR),
   LAB_CERT_CD3        VARCHAR2 (1000 CHAR),
   LAB_CERT_CD4        VARCHAR2 (1000 CHAR),
   LAB_CERT_CD5        VARCHAR2 (1000 CHAR),
   LAB_CERT_CD6        VARCHAR2 (1000 CHAR),
   LAB_CERT_CD7        VARCHAR2 (1000 CHAR),
   LAB_CERT_CD8        VARCHAR2 (1000 CHAR),
   XREF1               VARCHAR2 (1000 CHAR),
   XREF2               VARCHAR2 (1000 CHAR),
   XREF3               VARCHAR2 (1000 CHAR),
   XREF4               VARCHAR2 (1000 CHAR),
   XREF5               VARCHAR2 (1000 CHAR),
   COV_CODE            VARCHAR2 (1000 CHAR),
   ASC_GPCD            VARCHAR2 (1000 CHAR),
   ASC_EFF_DT          VARCHAR2 (1000 CHAR),
   BETOS               VARCHAR2 (1000 CHAR),
   TOS1                VARCHAR2 (1000 CHAR),
   TOS2                VARCHAR2 (1000 CHAR),
   TOS3                VARCHAR2 (1000 CHAR),
   TOS4                VARCHAR2 (1000 CHAR),
   TOS5                VARCHAR2 (1000 CHAR),
   ANES_UNIT           VARCHAR2 (1000 CHAR),
   ADD_DATE            DATE,
   ACT_EFF_DT          DATE,
   TERM_DT             DATE,
   ACTION_CODE         VARCHAR2 (1000 CHAR)
) NOLOGGING;

SPOOL OFF
EXIT