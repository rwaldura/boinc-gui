#!/bin/sh
#
# Runs hourly; collects all data from the cluster, and stores it to database.
# 

readonly DATABASE=boinc_cluster_state.db
# readonly DATABASE=t/_test.db

readonly temp=/tmp/boinc-gui-$$
readonly temp_state=$temp-state.xml
readonly temp_messages=$temp-messages.xml
readonly temp_notices=$temp-notices.xml
readonly temp_results=$temp-results.xml

readonly latest_state=/tmp/boinc_cluster_state.xml

cd ~/boinc-gui

echo -n "dumping cluster state... "
./boinc_cluster_state.xml get_state > $temp_state && 
	echo OK

echo -n "getting latest messages... "
./get_messages.xml > $temp_messages && 
	echo OK

echo -n "getting cluster notices... "
./boinc_cluster_state.xml get_notices > $temp_notices && 
	echo OK

echo -n "getting old results... "
./boinc_cluster_state.xml get_old_results > $temp_results && 
	echo OK

# update SQL database
echo -n "updating SQL database... "
xsltproc sql.xsl $temp_state $temp_messages $temp_notices $temp_results | 
	sqlite3 $DATABASE &&
		echo OK

# update XML database
echo -n "updating XML database... "
basex -c "open boinc; add $temp_state" &&
	echo OK

# keep around the latest state: used by Web GUI
rm $latest_state
ln $temp_state $latest_state

rm $temp_state $temp_messages $temp_notices $temp_results
