OPTIONS (errors=0, SKIP=1, direct=true)
LOAD DATA
CHARACTERSET UTF8
INFILE 'LOINC_FORMS.txt'
BADFILE 'LOINC_FORMS.bad'
DISCARDFILE 'LOINC_FORMS.dsc'                                                           
TRUNCATE
INTO TABLE LOINC_FORMS                                                                
FIELDS TERMINATED BY ";" OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS                                                             
(                                                                               
   ParentId                     FILLER
 , ParentLoinc                  CHAR    
 , ParentName					FILLER
 , Id 							FILLER
 , Sequence                		FILLER
 , Loinc          				CHAR           
)                                                                               
