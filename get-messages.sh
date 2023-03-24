#!/bin/sh
#
# Get new messages only.
#

readonly DATABASE=boinc_cluster_state.db

# get max seqno per node
maxseqno=$( sqlite3 -noheader -list -separator ' ' "$DATABASE" <<_SQL_
SELECT 
    h.hostname,
    ifnull(max(seqno), 0)
FROM 
    -- LEFT JOIN in case this is a new host that has no messages yet
    host h LEFT JOIN message USING (host_cpid)
GROUP BY 1
_SQL_
)

# if database cannot be read, maxseqno is blank, and everything is fine:
# we'll just get all messages for all nodes
./boinc_cluster_state.xml get_messages $maxseqno
