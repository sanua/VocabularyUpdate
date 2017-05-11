set cur_path=%cd%
set uname=DEV_JENKINS
set pwd=123
set tns=OMOPCA
call E:\Vocabulary_Data\DEV_HCPCS\_get_uname_pwn.bat
cd %cur_path%

rem echo Clear data...
rem sqlplus %uname%/%pwd% @prepare_manual_table.sql
rem echo done...

echo Importing data...
sqlldr.exe USERID=%uname%/%pwd%@%tns% CONTROL=../manual_table_import.ctl DATA=./_without_manual/manual_table_data.csv LOG=import_manual_table.log BAD=import_manual_table.bad DISCARD=import_manual_table.dsc
echo done...