#!/bin/sh

cd ..
./boinc_cluster_state.xml > t/_boinc_cluster_state.xml || exit 1

grep -c "<host_info>" t/_boinc_cluster_state.xml
grep -c "<result>" t/_boinc_cluster_state.xml

exit $?