<?xml version="1.0" encoding="UTF-8"?>
<!--
	Convert to HTML a XML document describing the state of the
	BOINC cluster. This present stylesheet is referenced in the
	source XML doc, and executed (processed) client-side, by the browser.

	See also
	https://developer.mozilla.org/en-US/docs/Web/EXSLT
	https://boinc.berkeley.edu/trac/wiki/GuiRpcProtocol#get_state
  -->
<x:stylesheet 
	xmlns:x="http://www.w3.org/1999/XSL/Transform" 
	xmlns:set="http://exslt.org/sets"
	version="1.0">

	<x:output method="html" encoding="UTF-8" />

	<x:template match="/">
		<html>
			<head>
				<link rel="stylesheet" href="styles.css" />
				<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js" />
				<script type="text/javascript">
			        google.charts.load('current', { 'packages': [ 'corechart', 'table' ] });

			        google.charts.setOnLoadCallback( function () 
					{
	  					var dt = new google.visualization.DataTable();
	  					dt.addColumn('string', 'result');
	  					dt.addColumn('string', 'app');
	  					dt.addColumn('string', 'project');
	  					dt.addColumn('string', 'host');
	  					dt.addColumn('number', 'ops');
		
						// populate the dataTable
	  					<x:apply-templates mode="dataTable" />

						// SELECT app, SUM(ops) FROM dt GROUP BY app
						var grouped = google.visualization.data.group(
							dt,
							[ 1 ], // "app" column
							[ { 'column': 4, 'aggregation': google.visualization.data.sum, 'type': 'number' } ] );
						
						var chart = new google.visualization.PieChart( document.getElementById('chart_div') );
						chart.draw(
							grouped, 
							{	// chart options
								fontName: "Google Sans", // matches styles.css
							} );
					} );					
				</script>
			</head>
			<body>
				<table>
					<tr>
						<td valign="top">
							<div class="chart_title">Cluster Utilization by App</div>
							<div id="chart_div"/> <!-- pie chart -->
						</td>
						<td>
							<x:apply-templates mode="html" />
						</td>
					</tr>
				</table>
			</body>
		</html>
	</x:template>

	<!-- ************************************************************************
		Create data table. 
	-->	
	<x:template match="boinc_cluster_state" mode="dataTable">
		<x:apply-templates select="boinc_client/boinc_gui_rpc_reply/client_state/result" mode="dataTable">
			<x:sort select="name" /> <!-- to group the same apps together -->
		</x:apply-templates>
	</x:template>	
	
	<!-- results with active tasks -->
	<x:template match="result[active_task]" mode="dataTable">
		<!-- get related structs -->
		<x:variable name="project"     select="../project[master_url = current()/project_url]" />
		<x:variable name="workunit"    select="../workunit[name = current()/wu_name]" />
		<x:variable name="app_version" select="../app_version[app_name = $workunit/app_name]" />
		<x:variable name="app"         select="../app[name = $workunit/app_name]" />
		<x:variable name="host"        select="../host_info" />
		dt.addRow( [
			'<x:value-of select="name" />',							// result
			'<x:value-of select="$app/user_friendly_name" />',		// app
			'<x:value-of select="$project/project_name" />',		// project
			'<x:value-of select="$host/domain_name" />',			// host
			<x:value-of select="$host/p_fpops + $host/p_iops" /> 	// ops
			] );			
	</x:template>	

	<!-- ************************************************************************
		Create a HTML table displaying each task in progress. 
	--> 
	<x:template match="boinc_cluster_state" mode="html">
		<table id="boinc_cluster_state">
			<tr>
				<th>App</th>
				<th>Project</th>
				<th>Node</th>
				<th/>
			</tr>
			<x:apply-templates select="boinc_client/boinc_gui_rpc_reply/client_state/result" mode="html">
				<x:sort select="name" /> <!-- to group the same apps together -->
				<x:sort select="../host_info/domain_name" />
			</x:apply-templates>
		</table>
		<div class="note">
			<p>Updated <x:value-of select="@created" /></p>
		</div>		
	</x:template>

	<!-- results with active tasks -->
	<x:template match="result[active_task]" mode="html">
		<!-- get related structs -->
		<x:variable name="project"     select="../project[master_url = current()/project_url]" />
		<x:variable name="workunit"    select="../workunit[name = current()/wu_name]" />
		<x:variable name="app_version" select="../app_version[app_name = $workunit/app_name]" />
		<x:variable name="app"         select="../app[name = $workunit/app_name]" />
		<x:variable name="host"        select="../host_info" />
		<tr>
			<td>
				<x:value-of select="$app/user_friendly_name" /> 
				<x:comment>
					<x:value-of select="$app_version/app_name" /> 
					<x:value-of select="$app_version/version_num" />
				</x:comment>
			</td>
			<td>
			    <a>
					<x:attribute name="href">
						<x:value-of select="$project/master_url" />
					</x:attribute>
					<x:value-of select="$project/project_name" /> 
			     </a>
			</td>
			<td>
				<div class="tooltip">
					<x:value-of select="$host/domain_name" />				
					<span class="tooltip-text">
						<x:value-of select="$host/product_name" />
						<x:comment>
							<x:value-of select="$host/os_version" />							
						</x:comment>
					</span>
				</div>
			</td>
			<td>
				<x:apply-templates />
			</td>
		</tr>			   
	</x:template>

	<!-- active tasks that are in progress -->
	<x:template match="active_task[fraction_done &gt; 0]">
		<div class="tooltip">
			<span class="tooltip-text">
				<x:value-of select="round(100 * fraction_done)"/>%
			</span>
			<x:variable name="progress_bar_width" select="150" /> <!-- defined in styles.css -->
			<div class="progress-bar-bg" />
			<div class="progress-bar">
				<x:attribute name="style">
					width: <x:value-of select="round($progress_bar_width * fraction_done)"/>px 
				</x:attribute>
			</div>
		</div>
	</x:template>
		
	<!-- ignore stray text in all nodes -->
	<x:template match="text()" />	
	<x:template match="text()" mode="html" />	
	<x:template match="text()" mode="dataTable" />	

</x:stylesheet>
