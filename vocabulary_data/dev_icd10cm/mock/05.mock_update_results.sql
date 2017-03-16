/* If any errors occurs - stop script execution and return error code */
WHENEVER SQLERROR EXIT SQL.SQLCODE
/*
 *****************************
 *  Log to file...    
 *****************************
*/
SPOOL &1

PROMPT
PROMPT 'Update Results' is starting...
EXECUTE dbms_lock.sleep(1);
PROMPT 'Update Results' is done...
PROMPT

EXIT