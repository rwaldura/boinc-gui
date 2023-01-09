#!/bin/sh

temp=/tmp/boinc-gui-$$.xml
~/boinc-gui/boinc_cluster_state.xml > $temp

# update XML database
basex -c "open boinc; add $temp"

# update SQL database
xsltproc sql.xsl $temp | sqlite3 ~/boinc-gui/boinc_cluster_state.db

rm $temp

