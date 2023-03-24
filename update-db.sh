#!/bin/sh

temp=/tmp/boinc-gui-$$
temp_state=$temp-state.xml
temp_messages=$temp-messages.xml
temp_notices=$temp-notices.xml

cd ~/boinc-gui

./boinc_cluster_state.xml get_state > $temp_state && 
	echo "dumped cluster state"

./get-messages.sh > $temp_messages && 
	echo "dumped cluster messages"

./boinc_cluster_state.xml get_notices > $temp_notices && 
	echo "dumped cluster notices"

# update SQL database
xsltproc sql.xsl $temp_state $temp_messages $temp_notices | 
	sqlite3 boinc_cluster_state.db &&
		echo "updated SQL database"

# update XML database
basex -c "open boinc; add $temp_state" &&
	echo "updated XML database"

rm $temp_state $temp_messages $temp_notices
