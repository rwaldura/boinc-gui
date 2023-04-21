--
-- Database schema.
--

-- ---------------------------------------------------------------------------
-- host details
CREATE TABLE host (
    host_cpid STRING PRIMARY KEY,
    updated DATETIME,
    domain_name STRING, -- the name self-reported by the BOINC client
    hostname STRING,    -- how we actually reached the client, could be an IP address
    p_ncpus INTEGER,
    p_vendor STRING,
    p_model STRING,
    os_name STRING,
    os_version STRING,
    product_name STRING,
    p_mfpops INTEGER,   -- mega-ops (*10^6), floating point
    p_miops INTEGER,    -- mega-ops, integer
    message_count INTEGER
);

-- ---------------------------------------------------------------------------
CREATE TABLE task (
    task_id INTEGER PRIMARY KEY AUTOINCREMENT,
    fraction_done DOUBLE,
    active_task_state INTEGER REFERENCES task_state(code),
    scheduler_state INTEGER REFERENCES scheduler_state(code),
    current_cpu_time DOUBLE,
    elapsed_time DOUBLE,
    progress_rate DOUBLE
);

-- ---------------------------------------------------------------------------
-- computational state
CREATE TABLE result (
    name STRING NOT NULL,
    host_cpid STRING NOT NULL REFERENCES host(host_cpid),
    created DATETIME,           -- the time we "saw" this result, i.e. every hour
    wu_name STRING,
    wu_rsc_mfpops_est INTEGER,  -- megaflops
    app_name STRING,
    app_user_friendly_name STRING,
    app_version_num INTEGER,
    app_version_mflops INTEGER, -- megaflops
    project_name STRING,
    project_master_url STRING,
    final_cpu_time DOUBLE,      -- seconds
    final_elapsed_time DOUBLE,  -- seconds
    exit_status INTEGER,
    state INTEGER REFERENCES result_state(code),
    report_deadline DATETIME,
    received DATETIME,
    estimated_cpu_time_remaining DOUBLE,
    task_id INTEGER REFERENCES task(task_id)
);

CREATE INDEX result_created ON result(created);
CREATE INDEX result_created_date ON result(date(created));
CREATE INDEX result_created_datetime ON result(datetime(created));

-- ---------------------------------------------------------------------------
CREATE TABLE message (
    updated DATETIME,
    created DATETIME,
    project_name STRING,
    body STRING,
    pri INTEGER, 
    seqno INTEGER,      -- resets upon client restart
    hostname STRING,    -- how we actually reached the client, could be an IP address
    host_cpid STRING REFERENCES host(host_cpid)
);

CREATE UNIQUE INDEX message_unique ON message(host_cpid, created, seqno);

-- ---------------------------------------------------------------------------
CREATE TABLE notice (
    updated DATETIME,
    created DATETIME,
    arrived DATETIME,
    title STRING,
    description STRING,  
    is_private BOOLEAN,
    project_name STRING,
    category STRING,
    link STRING,
    seqno INTEGER,
    hostname STRING,    -- how we actually reached the client, could be an IP address
    host_cpid STRING REFERENCES host(host_cpid)
);

CREATE UNIQUE INDEX notice_unique ON notice(host_cpid, created, seqno);

-- ---------------------------------------------------------------------------
-- convenient join between tables above
DROP VIEW IF EXISTS instant_cluster_state;
CREATE VIEW instant_cluster_state AS
    SELECT 
	    app_name,
	    domain_name,
        round(100 * t.fraction_done) AS '%done',
        datetime(r.created, 'localtime') AS updated
    FROM 
        result r 
        JOIN host h USING (host_cpid) 
        LEFT JOIN task t USING (task_id)
    WHERE
        r.created = (SELECT max(created) FROM result)
        AND active_task_state = 1
    ORDER BY
        app_name, domain_name;

-- simplified view of hosts 
DROP VIEW IF EXISTS hosts;
CREATE VIEW hosts AS 
    select domain_name, hostname, product_name, p_ncpus, p_mfpops, p_miops
    from host 
    order by 1;

-- ---------------------------------------------------------------------------
CREATE TABLE result_state (
    code INTEGER PRIMARY KEY,
    shortname STRING,
    name STRING,
    description STRING
);

CREATE TABLE task_state (
    code INTEGER PRIMARY KEY,
    shortname STRING,
    name STRING,
    description STRING
);

CREATE TABLE scheduler_state (
    code INTEGER PRIMARY KEY,
    shortname STRING,
    name STRING,
    description STRING
);

-- https://github.com/BOINC/boinc/blob/master/lib/common_defs.h
-- #define RESULT_NEW                  0    // New result
-- #define RESULT_FILES_DOWNLOADING    1    // Input files for result (WU, app version) are being downloaded
-- #define RESULT_FILES_DOWNLOADED     2    // Files are downloaded, result can be (or is being) computed
-- #define RESULT_COMPUTE_ERROR        3    // computation failed; no file upload
-- #define RESULT_FILES_UPLOADING      4    // Output files for result are being uploaded
-- #define RESULT_FILES_UPLOADED       5    // Files are uploaded, notify scheduling server at some point
-- #define RESULT_ABORTED              6    // result was aborted
-- #define RESULT_UPLOAD_FAILED        7    // some output file permanent failure
--
-- values of ACTIVE_TASK::task_state
-- #define PROCESS_UNINITIALIZED   0        // process does not exist yet
-- #define PROCESS_EXECUTING       1        // process is running, as far as we know
-- #define PROCESS_SUSPENDED       9        // we sent it a "suspend" message
-- #define PROCESS_ABORT_PENDING   5        // process exceeded limits; send "abort" message, waiting to exit
-- #define PROCESS_QUIT_PENDING    8        // we sent it a "quit" message, waiting to exit
-- #define PROCESS_COPY_PENDING    10       // waiting for async file copies to finish
--
-- values of ACTIVE_TASK::scheduler_state and ACTIVE_TASK::next_scheduler_state
-- "SCHEDULED" doesn't mean the task is actually running;
-- e.g. it won't be running if tasks are suspended or CPU throttling is in use
-- #define CPU_SCHED_UNINITIALIZED   0
-- #define CPU_SCHED_PREEMPTED       1
-- #define CPU_SCHED_SCHEDULED       2

-- perl -ne '$c = chr(39); 
-- if (($word, $code, $descr) = m{^-- #define (\w+)\s+(\d+)\s*/* *(.*)}) { 
--     $w = $word; $w =~ s/^([A-Z]+)_//; 
--     print "INSERT INTO XXX VALUES ($code, $c$w$c, $c$word$c, $c$descr$c);\n" 
-- }' < schema.sql >> schema.sql

INSERT INTO result_state VALUES (0, 'NEW', 'RESULT_NEW', 'New result');
INSERT INTO result_state VALUES (1, 'FILES_DOWNLOADING', 'RESULT_FILES_DOWNLOADING', 'Input files for result (WU, app version) are being downloaded');
INSERT INTO result_state VALUES (2, 'FILES_DOWNLOADED', 'RESULT_FILES_DOWNLOADED', 'Files are downloaded, result can be (or is being) computed');
INSERT INTO result_state VALUES (3, 'COMPUTE_ERROR', 'RESULT_COMPUTE_ERROR', 'computation failed; no file upload');
INSERT INTO result_state VALUES (4, 'FILES_UPLOADING', 'RESULT_FILES_UPLOADING', 'Output files for result are being uploaded');
INSERT INTO result_state VALUES (5, 'FILES_UPLOADED', 'RESULT_FILES_UPLOADED', 'Files are uploaded, notify scheduling server at some point');
INSERT INTO result_state VALUES (6, 'ABORTED', 'RESULT_ABORTED', 'result was aborted');
INSERT INTO result_state VALUES (7, 'UPLOAD_FAILED', 'RESULT_UPLOAD_FAILED', 'some output file permanent failure');

INSERT INTO task_state VALUES (0, 'UNINITIALIZED', 'PROCESS_UNINITIALIZED', 'process does not exist yet');
INSERT INTO task_state VALUES (1, 'EXECUTING', 'PROCESS_EXECUTING', 'process is running, as far as we know');
INSERT INTO task_state VALUES (9, 'SUSPENDED', 'PROCESS_SUSPENDED', 'we sent it a "suspend" message');
INSERT INTO task_state VALUES (5, 'ABORT_PENDING', 'PROCESS_ABORT_PENDING', 'process exceeded limits; send "abort" message, waiting to exit');
INSERT INTO task_state VALUES (8, 'QUIT_PENDING', 'PROCESS_QUIT_PENDING', 'we sent it a "quit" message, waiting to exit');
INSERT INTO task_state VALUES (10, 'COPY_PENDING', 'PROCESS_COPY_PENDING', 'waiting for async file copies to finish');

INSERT INTO scheduler_state VALUES (0, 'UNINITIALIZED', 'CPU_SCHED_UNINITIALIZED', NULL);
INSERT INTO scheduler_state VALUES (1, 'PREEMPTED', 'CPU_SCHED_PREEMPTED', NULL);
INSERT INTO scheduler_state VALUES (2, 'SCHEDULED', 'CPU_SCHED_SCHEDULED', NULL);
