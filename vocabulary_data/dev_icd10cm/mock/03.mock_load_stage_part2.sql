SET VERIFY OFF
/* If any errors occurs - stop script execution and return error code */
WHENEVER SQLERROR EXIT SQL.SQLCODE
/*
 *****************************
 *  Log to file...    
 *****************************
*/
SPOOL '&1'

PROMPT
PROMPT 'Load Stage part 2' is starting...
EXECUTE DBMS_LOCK.sleep(1);
PROMPT 'Load Stage part 2' is done...
PROMPT

EXIT