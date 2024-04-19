#!/bin/zsh

readonly DATABASE=boinc_cluster_state.db
# readonly DATABASE=t/_test.db

readonly XSLT="workunit.xsl"

readonly WORKUNIT_NAME=$QUERY_STRING

cat << _HTML_
Content-type: text/xml; charset=UTF-8

<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet href="$XSLT" type="text/xsl" ?>
<html>
<head></head>
<body>
<table>
_HTML_

sqlite3 -html $DATABASE <<_SQL_
SELECT
    r.name,
    strftime('%Y-%m-%d %H:%M', r.captured, 'localtime') as captured, 
    result_state.shortname AS result_state,
    task_state.shortname AS task_state,
    round(100 * fraction_done, 0) as '%done',
    CASE
        WHEN estimated_cpu_time_remaining = 0 THEN NULL
        WHEN estimated_cpu_time_remaining > 24 * 60 * 60 THEN round(estimated_cpu_time_remaining / (24 * 60 * 60)) || ' days'
        WHEN estimated_cpu_time_remaining > 60 * 60 THEN round(estimated_cpu_time_remaining / (60 * 60)) || ' hours'
        WHEN estimated_cpu_time_remaining > 60 THEN round(estimated_cpu_time_remaining / 60) || ' minutes'
    END AS remaining,
    CASE
        WHEN final_elapsed_time = 0 THEN NULL
        WHEN final_elapsed_time > 24 * 60 * 60 THEN round(final_elapsed_time / (24 * 60 * 60)) || ' days'
        WHEN final_elapsed_time > 60 * 60 THEN round(final_elapsed_time / (60 * 60)) || ' hours'
        WHEN final_elapsed_time > 60 THEN round(final_elapsed_time / 60) || ' minutes'
    END AS elapsed,
    exit_status, 
    app_name AS BOINC_App,  
    domain_name,
    strftime('%Y-%m-%d %H:%M', r.received, 'localtime') as received,
    strftime('%Y-%m-%d %H:%M', r.completed, 'localtime') as completed,
    strftime('%Y-%m-%d %H:%M', r.reported, 'localtime') as reported
FROM
    result r
    JOIN host h USING (host_cpid) 
    LEFT JOIN task USING (task_id) 
    LEFT JOIN result_state ON state = result_state.code  
    LEFT JOIN task_state ON active_task_state = task_state.code
WHERE
	wu_name = '$WORKUNIT_NAME'
ORDER BY 
	captured
_SQL_

cat << _HTML_
</table>
</body>
</html>
_HTML_
