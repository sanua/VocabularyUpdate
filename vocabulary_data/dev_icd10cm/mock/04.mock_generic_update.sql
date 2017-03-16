/* If any errors occurs - stop script execution and return error code */
WHENEVER SQLERROR EXIT SQL.SQLCODE
/*
 *****************************
 *  Log to file...    
 *****************************
*/
SPOOL &1

PROMPT
PROMPT 'Generic Update' is starting...
EXECUTE dbms_lock.sleep(1);
PROMPT 'Generic Update' is done...
PROMPT

EXIT