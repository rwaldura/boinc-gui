#!/bin/sh

# create schema if no db
test -f _test.db || sqlite3 _test.db < ../schema.sql || exit 1

sqlite3 _test.db < _update.sql || exit 1

num_hosts=$( sqlite3 -noheader -list _test.db "SELECT COUNT(*) FROM host" )
# echo "$num_hosts host records"
test "$num_hosts" -gt 1 || exit 1

num_results=$( sqlite3 -noheader -list _test.db "SELECT COUNT(*) FROM result" )
# echo "$num_results result records"
test "$num_results" -gt "$num_hosts" || exit 1

sqlite3 _test.db "
SELECT 
	strftime('%Y-%m-%d %H:%M', r.updated, 'localtime') as updated, 
	round(100 * active_task_fraction_done) as '%done', 
	app_name || '-' || app_version_num AS BOINC_App,
	app_version_mflops AS app_mops,
	domain_name,
	p_mfpops + p_miops AS host_mops
FROM 
	result r JOIN host h USING (host_cpid) 
ORDER BY 
	updated DESC, domain_name"
	
exit $?