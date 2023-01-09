#!/bin/sh

temp=/tmp/boinc-gui-$$.xml

cd ~/boinc-gui

./boinc_cluster_state.xml > $temp && 
	echo "dumped cluster state"

# update SQL database
xsltproc sql.xsl $temp | 
	sqlite3 boinc_cluster_state.db &&
		echo "updated SQL db"

# update XML database
basex -c "open boinc; add $temp" &&
	echo "updated XML db"

rm $temp

