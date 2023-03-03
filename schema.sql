--
-- Database schema.
--

-- store host details
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

-- store computational state
CREATE TABLE result (
	result_name STRING PRIMARY KEY,
	host_cpid STRING NOT NULL,
	updated DATETIME,
	wu_name STRING,
	wu_rsc_mfpops_est INTEGER,	-- megaflops
	app_name STRING,
	app_user_friendly_name STRING,
	app_version_num INTEGER,
	app_version_mflops INTEGER,	-- megaflops
	project_name STRING,
	project_master_url STRING,
	active_task_fraction_done DOUBLE,
	
	FOREIGN KEY (host_cpid) REFERENCES host(host_cpid)
);

-- store computational state
CREATE TABLE result1 (
	result_name STRING NOT NULL,
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
	active_task_fraction_done DOUBLE,
	
	FOREIGN KEY (host_cpid) REFERENCES host(host_cpid)
);

-- natural join between both tables above
DROP VIEW IF EXISTS cluster_state;
CREATE VIEW cluster_state AS
	SELECT 
		datetime(r.updated, 'localtime') AS updated,
		round(100 * active_task_fraction_done) AS frac_done,
		app_name || '-' || app_version_num AS app,
		app_version_mflops AS app_mops,
		wu_rsc_mfpops_est,
		domain_name,
		p_mfpops + p_miops AS host_mops
	FROM 
		result r JOIN host h USING (host_cpid) 
	ORDER BY 
		updated DESC, domain_name;

 -- view latest result
DROP VIEW IF EXISTS instant_cluster_state;
CREATE VIEW instant_cluster_state AS
	SELECT * FROM cluster_state 
	WHERE updated = datetime((SELECT max(updated) FROM result), 'localtime');
