set echo off
set uname=DEV_JENKINS
set pwd=123
set tns=OMOPCA
sqlplus %uname%/%pwd%@%tns% @manual_table_extract.sql . MANUAL_table.csv MANUAL_table