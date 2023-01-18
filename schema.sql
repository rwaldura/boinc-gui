--
-- Database schema.
--
-- Example query:
--
--	SELECT strftime('%Y-%m-%d %H:%M', r.updated, 'localtime') as updated, round(100 * active_task_fraction_done), result_name, domain_name
--	FROM result r JOIN host h USING (host_cpid) 
--	ORDER BY updated DESC, domain_name;
--

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
