#!/bin/sh

readonly temp=/tmp/boinc-gui-$$
readonly temp_state=$temp-state.xml
readonly temp_messages=$temp-messages.xml
readonly temp_notices=$temp-notices.xml

readonly latest_state=/tmp/boinc_cluster_state.xml

cd ~/boinc-gui

./boinc_cluster_state.xml get_state > $temp_state && 
	echo "dumped cluster state"

./get_messages.xml > $temp_messages && 
	echo "got latest messages"

./boinc_cluster_state.xml get_notices > $temp_notices && 
	echo "got cluster notices"

# update SQL database
xsltproc sql.xsl $temp_state $temp_messages $temp_notices | 
	sqlite3 boinc_cluster_state.db &&
		echo "updated SQL database"

# update XML database
basex -c "open boinc; add $temp_state" &&
	echo "updated XML database"

# keep around the latest state: used by Web GUI
rm $latest_state
ln $temp_state $latest_state

rm $temp_state $temp_messages $temp_notices
