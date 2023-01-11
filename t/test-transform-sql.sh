#!/bin/sh

xsltproc ../sql.xsl _boinc_cluster_state.xml > _update.sql || exit 1

num_hosts=$( grep -c "INSERT OR REPLACE INTO host" _update.sql )
# echo "$num_hosts host INSERTs"
test "$num_hosts" -gt 1 || exit 1

num_results=$( grep -c "INSERT OR REPLACE INTO result" _update.sql )
# echo "$num_results result INSERTs"

test "$num_results" -gt "$num_hosts"
exit $?