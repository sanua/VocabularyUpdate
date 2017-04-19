SET VERIFY OFF
/* If any errors occurs - stop script execution and return error code */
WHENEVER SQLERROR EXIT SQL.SQLCODE
/*
 *****************************
 *  Log to file...    
 *****************************
*/
SPOOL &1

PROMPT 'Procedure Drug' is starting...
EXECUTE dbms_lock.sleep(1);
PROMPT 'Procedure Drug' is done...