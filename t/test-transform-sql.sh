#!/bin/sh

xsltproc ../sql.xsl _boinc_cluster_state.xml _messages.xml _notices.xml > _update.sql || exit 1

num_hosts=$( grep -c "INSERT OR REPLACE INTO host" _update.sql )
echo "$num_hosts host INSERTs"
test "$num_hosts" -gt 1 || exit 1

num_results=$( grep -c "INSERT INTO result" _update.sql )
echo "$num_results result INSERTs"
test "$num_results" -gt 1 || exit 1

test "$num_results" -gt "$num_hosts"

num_messages=$( grep -c "INSERT OR REPLACE INTO message" _update.sql )
echo "$num_messages message INSERTs"
test "$num_messages" -gt 1 || exit 1

num_notices=$( grep -c "INSERT OR REPLACE INTO notice" _update.sql )
echo "$num_notices notice INSERTs"
test "$num_notices" -gt 1 || exit 1

test "$num_messages" -gt "$num_notices"

exit $?