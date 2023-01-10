<?xml version="1.0" encoding="UTF-8"?>
<!--
	Populate (update) database with latest cluster state.

	CREATE TABLE host (
		host_cpid STRING PRIMARY KEY,
		updated DATETIME,
		domain_name STRING,
		hostname STRING,
		p_ncpus INTEGER,
		p_vendor STRING,
		p_model STRING,
		os_name STRING,
		os_version STRING,
		product_name STRING,
		p_mfpops INTEGER,
		p_miops INTEGER
	);

	CREATE TABLE result (
		result_name STRING PRIMARY KEY,
		host_cpid STRING NOT NULL,
		updated DATETIME,
		wu_name STRING,
		app_name STRING,
		app_user_friendly_name STRING,
		app_version_num INTEGER,
		app_version_mflops INTEGER,
		project_name STRING,
		project_master_url STRING,
		active_task_fraction_done DOUBLE,
		FOREIGN KEY (host_cpid) REFERENCES host(host_cpid)
	);

	Example query:

	SELECT result_name, domain_name, strftime('%Y-%m-%d %H:%M', r.updated, 'localtime') 
	FROM result r JOIN host h USING (host_cpid) 
	ORDER BY domain_name;

	See also
	https://boinc.berkeley.edu/trac/wiki/GuiRpcProtocol#get_state
  -->
<x:stylesheet 
	xmlns:x="http://www.w3.org/1999/XSL/Transform" 
	version="1.0">

	<x:output method="text" encoding="UTF-8" />

	<x:template match="/boinc_cluster_state">
		BEGIN;
		<x:apply-templates />		
		COMMIT;
	</x:template>	

	<!-- host_info -->
	<x:template match="host_info">
		INSERT OR REPLACE INTO host (
			updated,
			host_cpid,
			domain_name, -- the name self-reported by the BOINC client
			hostname, -- how we actually reached the client, could be an IP address
			p_ncpus,
			p_vendor,
			p_model,
			os_name,
			os_version,
			product_name,
			p_mfpops,
			p_miops
		) VALUES (
			'<x:value-of select="/boinc_cluster_state/@created" />' ,
			'<x:value-of select="host_cpid" />' ,
			'<x:value-of select="domain_name" />' ,
			'<x:value-of select="../../../@hostname" />', <!-- attribute of "boinc_client" element -->		
			<x:value-of select="p_ncpus" /> ,
			'<x:value-of select="p_vendor" />' ,
			'<x:value-of select="p_model" />' ,
			'<x:value-of select="os_name" />' ,
			'<x:value-of select="os_version" />' ,
			'<x:value-of select="product_name" />' ,
			<x:value-of select="round(p_fpops div 1000000)" /> ,
			<x:value-of select="round( p_iops div 1000000)" />
		);
	</x:template>	

	<!-- results in processing: have active task -->
	<x:template match="result[active_task]">
		<!-- get related structs -->
		<x:variable name="project"     select="../project[master_url = current()/project_url]" />
		<x:variable name="workunit"    select="../workunit[name = current()/wu_name]" />
		<x:variable name="app_version" select="../app_version[app_name = $workunit/app_name]" />
		<x:variable name="app"         select="../app[name = $workunit/app_name]" />
		<x:variable name="host"        select="../host_info" />

		INSERT OR REPLACE INTO result (
			updated,
			result_name,
			wu_name,
			host_cpid,
			app_name,
			app_user_friendly_name,
			app_version_num,
			app_version_mflops,
			project_name,
			project_master_url,
			active_task_fraction_done
		) VALUES (
			'<x:value-of select="/boinc_cluster_state/@created" />' ,
			'<x:value-of select="name" />' ,
			'<x:value-of select="wu_name" />' ,
			'<x:value-of select="$host/host_cpid" />' ,
			'<x:value-of select="$app/name" />' ,
			'<x:value-of select="$app/user_friendly_name" />' ,
			<x:value-of select="$app_version/version_num" /> ,
			<x:value-of select="round($app_version/flops div 1000000)" /> ,
			'<x:value-of select="$project/project_name" />' ,
			'<x:value-of select="$project/master_url" />' ,
			<x:value-of select="active_task/fraction_done" />
		);
	</x:template>	

	<!-- ignore stray text in all nodes -->
	<x:template match="text()" />	

</x:stylesheet>
