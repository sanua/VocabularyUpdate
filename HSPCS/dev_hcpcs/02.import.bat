REM Check id exists user name input batch and execute ii if so
echo off
REM set run_path=%cd%
set run_path=2016-Alpha-Numeric-HCPCS-File
set uname=DEV_HCPCS

if exist "..\_get_uname_pwn.bat" (
	cd ..
	call "_get_uname_pwn.bat"
) else (
	echo The file "_get_uname_pwn.bat" is not found in parent folder...
	exit
)

echo Used credentials: %uname%/%pwd%

echo Impotring data from '%run_path%' ...
REM cd %run_path%
sqlldr.exe USERID=%uname%/%pwd% CONTROL=2016-Alpha-Numeric-HCPCS-File\ANWEB_V2.ctl DATA=2016-Alpha-Numeric-HCPCS-File\ANWEB_V2.csv LOG=2016-Alpha-Numeric-HCPCS-File\ANWEB_V2.log BAD=2016-Alpha-Numeric-HCPCS-File\ANWEB_V2.bad DISCARD=2016-Alpha-Numeric-HCPCS-File\ANWEB_V2.dsc
