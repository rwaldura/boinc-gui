#!/bin/sh

cd ..
./boinc_cluster_state.xml get_state > t/_boinc_cluster_state.xml || exit 1
./boinc_cluster_state.xml get_messages > t/_messages.xml || exit 1
./boinc_cluster_state.xml get_notices > t/_notices.xml || exit 1

/bin/echo -n "#hosts = "    ; grep -c "<host_info>" t/_boinc_cluster_state.xml
/bin/echo -n "#results = "  ; grep -c "<result>" t/_boinc_cluster_state.xml
/bin/echo -n "#messages = " ; grep -c "<msg>" t/_messages.xml
/bin/echo -n "#notices = "  ; grep -c "<notice>" t/_notices.xml

exit $?