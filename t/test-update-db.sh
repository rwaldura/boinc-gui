#!/bin/sh

# create schema if no db
test -f _test.db || sqlite3 _test.db < ../schema.sql || exit 1

#sqlite3 _test.db < _update.sql || exit 1

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
-- ##### CLUSTER STATE ##########################

SELECT 
    strftime('%Y-%m-%d %H:%M', r.created, 'localtime') as updated, 
    strftime('%Y-%m-%d %H:%M', r.received, 'localtime') as received,    
    round(100 * t.fraction_done) as '%done', 
    result_state.shortname AS result_state,
	task_state.shortname AS task_state,
    iif(final_elapsed_time > 0, time(final_elapsed_time), NULL) AS total_elapsed,
    iif(estimated_cpu_time_remaining > 0, time(estimated_cpu_time_remaining), NULL) AS remaining,
    app_name || '-' || app_version_num AS BOINC_App,
    domain_name,
    p_mfpops + p_miops AS host_mops
FROM 
    result r JOIN host h USING (host_cpid) 
    LEFT JOIN task t using (task_id)
	LEFT JOIN result_state ON state = result_state.code
	LEFT JOIN task_state ON active_task_state = task_state.code
ORDER BY 
    created DESC, domain_name, 3;

-- ##### LAST LOG MESSAGE FOR EACH NODE ##########################

select
    datetime(created, 'localtime') as created, 
	m.hostname,
    domain_name, 
    project_name,
    substr(trim(body, X'0A'), 0, 50) as mesg
from 
    message m
    JOIN (select host_cpid, max(created) as created, max(seqno) as seqno from message group by 1)
    	USING (host_cpid, created, seqno)
    LEFT JOIN host using (host_cpid)
order by 1 desc;

-- ##### NOTICES ##########################

select
    title,
    substr(trim(description, X'0A'), 0, 50) as notice,
    group_concat(domain_name)
from 
    notice left join host using (host_cpid)
group by 1, 2;
_SQL_

exit $?
