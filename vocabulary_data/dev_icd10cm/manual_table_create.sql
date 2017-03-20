SET ECHO OFF
/* If any errors occurs - stop script execution and return error code */
WHENEVER SQLERROR EXIT SQL.SQLCODE
/*
 *****************************
 *  Log to file...    
 *****************************
*/

SPOOL &1

/* Delete Manual Table is exist */
DECLARE
	TYPE TStringArray IS TABLE OF VARCHAR2(255);
	t_names TStringArray := TStringArray('&2');
	l_cnt NUMBER;
	l_str VARCHAR2(255);
BEGIN
	FOR i in t_names.FIRST..t_names.LAST LOOP
	  l_str := t_names(i);
    SELECT COUNT(1) INTO l_cnt FROM user_tables WHERE UPPER(table_name) = UPPER(l_str);
    IF l_cnt > 0 THEN
      EXECUTE IMMEDIATE 'DROP TABLE ' || l_str;
    END IF;
	END LOOP;
END;
/

CREATE TABLE &2 AS
  SELECT * FROM CONCEPT WHERE ROWNUM < 6;

COMMIT;

EXIT