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
PROMPT 'Load Stage part 2' is starting...

/* Just pause for a second approx */
DECLARE
  start_date DATE := sysdate;
  current_date DATE;
  DELTA CONSTANT NUMBER := 1/(24*60*60);
BEGIN
	LOOP
    current_date := sysdate;
		EXIT WHEN current_date > start_date + DELTA;
	END LOOP;
END;
/

PROMPT 'Load Stage part 2' is done...
PROMPT

EXIT