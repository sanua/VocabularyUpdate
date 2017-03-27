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
PROMPT 'Generic Update' is starting...
BEGIN
	dbms_lock.sleep(1);
END;
/
PROMPT 'Generic Update' is done...
PROMPT

EXIT