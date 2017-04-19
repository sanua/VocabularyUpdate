set uname=DEV_ICD10CM
set pwd=%uname%
sqlldr.exe USERID=%uname%/%pwd% CONTROL=icd10cm.ctl DATA=icd10cm.txt LOG=icd10cm.log BAD=icd10cm.bad DISCARD=2016icd10cm.dsc