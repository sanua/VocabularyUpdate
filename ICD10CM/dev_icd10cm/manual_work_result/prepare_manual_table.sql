SET TERMOUT OFF
SET ECHO ON

/*
 *****************************
 *  Evaluate log file name...    
 *****************************
*/
SPOOL prepare_manual_table.log

truncate table manual_table;
commit;

SPOOL OFF
EXIT