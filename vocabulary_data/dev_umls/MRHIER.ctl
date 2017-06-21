options (direct=true, errors=0)
load data
CHARACTERSET UTF8
infile 'MRHIER.RRF' 
badfile 'MRHIER.bad'
discardfile 'MRHIER.dsc'
truncate
into table MRHIER
fields terminated by '|'
trailing nullcols(
 CUI CHAR,
 AUI CHAR,
 CXN CHAR,
 PAUI CHAR,
 SAB CHAR,
 RELA CHAR,
 PTR CHAR (1000),
 HCD CHAR,
 CVF INTEGER external
)
