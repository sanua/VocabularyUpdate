/* If any errors occurs - stop script execution and return error code */
WHENEVER SQLERROR EXIT SQL.SQLCODE
/*
 *****************************
 *  Log to file...    
 *****************************
*/
SPOOL &1

PROMPT
PROMPT 'Create Source Table' is starting...
EXECUTE dbms_lock.sleep(1);
PROMPT 'Create Source Table' is done...
PROMPT

EXIT