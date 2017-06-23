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
* Authors: Timur Vakhitov, Dmitry Dymshyts, Christian Reich
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
BEGIN
	EXECUTE IMMEDIATE 'DROP TABLE ICDCLAML';
	EXCEPTION
		WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE ICDCLAML
(
   xmlfield   XMLTYPE
);

SPOOL OFF
EXIT