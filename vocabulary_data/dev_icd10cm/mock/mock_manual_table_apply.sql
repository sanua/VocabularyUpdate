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

PROMPT
PROMPT Apply results of 'Manual Table...' is starting...
EXEC DBMS_LOCK.sleep(1);
PROMPT Appying  of 'Manual Table...' result is done...
PROMPT

SPOOL OFF
EXIT