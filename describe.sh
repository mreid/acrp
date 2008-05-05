#!/bin/bash
#
# Describes each of the tables in the ACRP database along with its size.
# Modify the USER, DB and PASS variables to work with local copy of database.
#
# AUTHOR: 	Mark Reid <mark.reid@anu.edu.au>
# CREATED	2008-04-01

USER=acrp
DB=acrp
PASS=acrppass

MYSQL_LIST="mysql --column-names=FALSE -u $USER --password=$PASS $DB"
MYSQL_TAB="mysql -t -u $USER --password=$PASS $DB"

echo "ACRP Table Schema"
echo "-----------------"
echo 

for f in `echo "show tables;" | $MYSQL_LIST` ; do
	echo -n "TABLE $f, SIZE = "
	echo "select count(*) from $f;" | $MYSQL_LIST
	echo "describe $f;" | $MYSQL_TAB
	echo
done
