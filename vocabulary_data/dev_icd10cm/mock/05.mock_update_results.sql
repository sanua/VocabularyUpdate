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
PROMPT 'Update Results' is starting...
BEGIN
	DBMS_LOCK.sleep(1);
END;
/
PROMPT 'Update Results' is done...
PROMPT

EXIT