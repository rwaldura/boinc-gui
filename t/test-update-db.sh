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

sqlite3 _test.db "
SELECT 
	strftime('%Y-%m-%d %H:%M', r.created, 'localtime') as updated, 
	round(100 * t.fraction_done) as '%done', 
	CASE -- https://github.com/BOINC/boinc/blob/master/lib/common_defs.h#L164
		WHEN state = 2 THEN 'FILES_DOWNLOADED'
		WHEN state = 4 THEN 'FILES_UPLOADING'
	END AS result_state,
	final_elapsed_time,
	estimated_cpu_time_remaining,
	app_name || '-' || app_version_num AS BOINC_App,
	app_version_mflops AS app_mops,
	domain_name,
	p_mfpops + p_miops AS host_mops
FROM 
	result r JOIN host h USING (host_cpid) 
	LEFT JOIN task t using (task_id)
ORDER BY 
	created DESC, domain_name, 2"
	
exit $?
