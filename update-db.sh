#!/bin/sh

temp=/tmp/boinc-gui-$$.xml
~/boinc-gui/boinc_cluster_state.xml > $temp
basex -c "open boinc; add $temp"
rm $temp

