--
-- Database schema.
--

-- ---------------------------------------------------------------------------
-- host details
CREATE TABLE host (
	host_cpid STRING PRIMARY KEY,
	updated DATETIME,
	domain_name STRING,	-- the name self-reported by the BOINC client
	hostname STRING,	-- how we actually reached the client, could be an IP address
	p_ncpus INTEGER,
	p_vendor STRING,
	p_model STRING,
	os_name STRING,
	os_version STRING,
	product_name STRING,
	p_mfpops INTEGER,	-- megaflops
	p_miops INTEGER		-- megaflops
);

-- ---------------------------------------------------------------------------
CREATE TABLE task (
	task_id INTEGER PRIMARY KEY AUTOINCREMENT,
	fraction_done DOUBLE,
	active_task_state INTEGER,
	scheduler_state INTEGER,
	current_cpu_time DOUBLE,
	elapsed_time DOUBLE,
	progress_rate DOUBLE	
);

-- ---------------------------------------------------------------------------
-- computational state
CREATE TABLE result (
	name STRING NOT NULL,
	host_cpid STRING NOT NULL,
	created DATETIME,
	wu_name STRING,
	wu_rsc_mfpops_est INTEGER,	-- megaflops
	app_name STRING,
	app_user_friendly_name STRING,
	app_version_num INTEGER,
	app_version_mflops INTEGER,	-- megaflops
	project_name STRING,
	project_master_url STRING,
	final_cpu_time DOUBLE,
	final_elapsed_time DOUBLE, 
	exit_status INTEGER,
	state INTEGER,
	report_deadline DOUBLE,
	received_time DOUBLE,
	estimated_cpu_time_remaining DOUBLE,
	task_id INTEGER,
	
	FOREIGN KEY (host_cpid) REFERENCES host(host_cpid),
	FOREIGN KEY (task_id) REFERENCES task(task_id)
);

CREATE INDEX result_created ON result(created);
CREATE INDEX result_created_date ON result(date(created));
CREATE INDEX result_created_datetime ON result(datetime(created));

-- ---------------------------------------------------------------------------
CREATE TABLE message (
	updated DATETIME,
	created DATETIME,
	project STRING,
	body STRING,
	pri INTEGER, 
	seqno INTEGER,
	host_cpid STRING,
	FOREIGN KEY (host_cpid) REFERENCES host(host_cpid)
);

CREATE UNIQUE INDEX message_unique ON message(host_cpid, created, seqno);

-- ---------------------------------------------------------------------------
CREATE TABLE notice (
	updated DATETIME,
	create_time DATETIME,
	arrival_time DATETIME,
	title STRING,
	description STRING,	 
	is_private BOOLEAN,
	project_name STRING,
	category STRING,
	link STRING,
	seqno INTEGER,
	host_cpid STRING,
	FOREIGN KEY (host_cpid) REFERENCES host(host_cpid)
);

CREATE UNIQUE INDEX notice_unique ON notice(host_cpid, create_time, seqno);

-- ---------------------------------------------------------------------------
-- convenient join between tables above
DROP VIEW IF EXISTS cluster_state;
CREATE VIEW cluster_state AS
	SELECT 
		datetime(r.created, 'localtime') AS created,
		round(100 * t.fraction_done) AS '%done',
		app_name || '-' || app_version_num AS app,
		domain_name
	FROM 
		result r 
		JOIN host h USING (host_cpid) 
		LEFT JOIN task t USING (task_id)
	ORDER BY 
		1 DESC, domain_name;

 -- view latest result
DROP VIEW IF EXISTS instant_cluster_state;
CREATE VIEW instant_cluster_state AS
	SELECT * FROM cluster_state 
	WHERE created = datetime((SELECT max(created) FROM result), 'localtime');
	
-- simplified view of hosts 
DROP VIEW IF EXISTS hosts;
CREATE VIEW hosts AS 
	select domain_name, hostname, product_name, p_ncpus, p_mfpops + p_miops as mops
	from host 
	order by 1;


-- ---------------------------------------------------------------------------
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
-- #define PROCESS_UNINITIALIZED   0        // process doesn't exist yet
-- #define PROCESS_EXECUTING       1        // process is running, as far as we know
-- #define PROCESS_SUSPENDED       9        // we've sent it a "suspend" message
-- #define PROCESS_ABORT_PENDING   5        // process exceeded limits; send "abort" message, waiting to exit
-- #define PROCESS_QUIT_PENDING    8        // we've sent it a "quit" message, waiting to exit
-- #define PROCESS_COPY_PENDING    10       // waiting for async file copies to finish
--
-- values of ACTIVE_TASK::scheduler_state and ACTIVE_TASK::next_scheduler_state
-- "SCHEDULED" doesn't mean the task is actually running;
-- e.g. it won't be running if tasks are suspended or CPU throttling is in use
-- #define CPU_SCHED_UNINITIALIZED   0
-- #define CPU_SCHED_PREEMPTED       1
-- #define CPU_SCHED_SCHEDULED       2
