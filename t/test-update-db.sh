#!/bin/sh

# create schema if no db
test -f _test.db || sqlite3 _test.db < ../schema.sql || exit 1

sqlite3 _test.db < _update.sql || exit 1

num_hosts=$( sqlite3 -noheader -list _test.db "SELECT COUNT(*) FROM host" )
echo "$num_hosts host records"
test "$num_hosts" -gt 1 || exit 1

num_results=$( sqlite3 -noheader -list _test.db "SELECT COUNT(*) FROM result" )
echo "$num_results result records"
test "$num_results" -gt "$num_hosts" || exit 1

num_messages=$( sqlite3 -noheader -list _test.db "SELECT COUNT(*) FROM message" )
echo "$num_messages message records"
test "$num_messages" -gt 1 || exit 1

num_notices=$( sqlite3 -noheader -list _test.db "SELECT COUNT(*) FROM notice" )
echo "$num_notices notice records"
test "$num_notices" -lt "$num_messages" || exit 1

sqlite3 _test.db <<_SQL_
select "##### CLUSTER STATE ##########################";

SELECT 
    strftime('%Y-%m-%d %H:%M', r.created, 'localtime') as updated, 
    strftime('%Y-%m-%d %H:%M', r.received, 'localtime') as received,    
    round(100 * t.fraction_done) as '%done', 
    CASE -- https://github.com/BOINC/boinc/blob/master/lib/common_defs.h#L164
        WHEN state = 2 THEN 'FILES_DOWNLOADED'
        WHEN state = 4 THEN 'FILES_UPLOADING'
    END AS result_state,
    iif(final_elapsed_time > 0, time(final_elapsed_time), NULL) AS total_elapsed,
    iif(estimated_cpu_time_remaining > 0, time(estimated_cpu_time_remaining), NULL) AS remaining,
    app_name || '-' || app_version_num AS BOINC_App,
    domain_name,
    p_mfpops + p_miops AS host_mops
FROM 
    result r JOIN host h USING (host_cpid) 
    LEFT JOIN task t using (task_id)
ORDER BY 
    created DESC, domain_name, 3;

select "##### LAST LOG MESSAGE FOR EACH NODE ##########################";

select
    datetime(created, 'localtime') as created, 
    domain_name, 
    project_name,
    substr(trim(body, X'0A'), 0, 50) as message
from 
    message JOIN 
    (select host_cpid, max(created) as created, max(seqno) as seqno from message group by 1)
    USING (created, seqno, host_cpid)
    LEFT JOIN host using (host_cpid)
order by 1 desc
_SQL_

exit $?
