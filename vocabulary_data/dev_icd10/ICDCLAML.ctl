OPTIONS (errors=0, direct=true)
LOAD DATA
CHARACTERSET UTF8
INFILE *                                                        
TRUNCATE
INTO TABLE ICDCLAML
xmltype(xmlfield)
(
	xmlfield LOBFILE (CONSTANT icdClaML.xml)  TERMINATED BY EOF
)
BEGINDATA
0