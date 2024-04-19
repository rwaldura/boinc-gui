-- ##### CLUSTER STATE ##########################
SELECT 
    strftime('%Y-%m-%d %H:%M', r.captured, 'localtime') as captured, 
    strftime('%Y-%m-%d %H:%M', r.received, 'localtime') as received,    
    round(100 * t.fraction_done) as '%done', 
    result_state.shortname AS result_state,
    task_state.shortname AS task_state,
    iif(final_elapsed_time > 0, time(final_elapsed_time), NULL) AS total_elapsed,
    iif(estimated_cpu_time_remaining > 0, time(estimated_cpu_time_remaining), NULL) AS remaining,
    app_name AS BOINC_App,
    domain_name,
    p_mfpops + p_miops AS host_mops
FROM 
    result r 
    JOIN host h USING (host_cpid) 
    LEFT JOIN task t using (task_id)
    LEFT JOIN result_state ON state = result_state.code
    LEFT JOIN task_state ON active_task_state = task_state.code
WHERE
    task_state.shortname = 'EXECUTING'
    and domain_name = 'droid68'
ORDER BY 
    captured DESC, domain_name, 3;

-- ##### CLUSTER STATE, BY NODE ##########################
WITH latest_results AS (
    SELECT
        host_cpid,
        MAX(captured) AS captured
    FROM
        result
    GROUP BY host_cpid
)
SELECT 
    domain_name,
    count(DISTINCT result.name) AS active_tasks,
    strftime('%Y-%m-%d %H:%M', max(result.captured), 'localtime') as updated
FROM 
    host
    LEFT JOIN latest_results USING (host_cpid)
    LEFT JOIN result USING (host_cpid, captured)
    LEFT JOIN task using (task_id)
    LEFT JOIN task_state ON active_task_state = task_state.code
WHERE
    task_state.shortname = 'EXECUTING'
GROUP BY 1
ORDER BY 1;

-- ##### LAST 5 LOG MESSAGES FOR EACH NODE ##########################
SELECT
    domain_name, 
    m.hostname,
    datetime(created, 'localtime') as created, 
    project_name,
    replace(substr(body, 0, 99), X'0A', '*') as mesg
FROM 
    message m
    LEFT JOIN host using (host_cpid)
WHERE 
    m.rowID IN (
        select rowID from message
        where host_cpid = m.host_cpid -- correlated subquery!
        order by created desc, seqno desc 
        limit 5 )
ORDER BY
    domain_name, created;

-- ##### LATEST LOG MESSAGES, GROUPED ##########################
SELECT
    count(*),
    substr(replace(body, X'0A', ' '), 0, 99) as mesg,
    group_concat(distinct project_name)
FROM 
    message m
WHERE 
    datetime(created) >= datetime('now', '-33 day')
--    AND hostname = '10.10.10.51'
GROUP BY 2
ORDER BY 1 DESC
LIMIT 10;

-- ##### LATEST LOG MESSAGES FOR ONE PROJECT, GROUPED ##########################
SELECT
    count(*),
    substr(replace(body, X'0A', ' '), 0, 99) as mesg,
    project_name
FROM 
    message m
WHERE 
    datetime(created) >= datetime('now', '-33 day')
    AND project_name = 'Universe@Home'
GROUP BY 2
ORDER BY 1 DESC
LIMIT 10;

-- ##### LOG MESSAGES FOR 1 PROJECT, 1 NODE ##########################
SELECT 
    strftime('%Y-%m-%d %H:%M', created, 'localtime') as created, 
    seqno,
    project_name,
    substr(replace(body, X'0A', ' '), 0, 99) as mesg 
FROM 
    message 
    JOIN host USING (host_cpid)
WHERE
    datetime(created) >= datetime('now', '-13 day')
    AND domain_name = 'droid06' 
    and project_name = 'Universe@Home'
ORDER BY
    created, seqno;

-- ##### NOTICES ##########################
select
    title,
    project_name,
    substr(replace(description, X'0A', ' '), 0, 99) as notice,
    count(*)
from 
    notice left join host using (host_cpid)
WHERE 
    datetime(created) >= datetime('now', '-33 day')
group by 1, 2, 3;

-- ##### HISTORY OF A WORKUNIT ##########
WITH param AS (SELECT 
	'xxx'
	AS wu_name)
select
    substr(r.name, 0, 33),
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
from 
    result r
    JOIN host h USING (host_cpid) 
    left join task using (task_id) 
    left join result_state on state = result_state.code  
    left join task_state on active_task_state = task_state.code
    join param using (wu_name)
order by captured;
