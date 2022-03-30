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
			        google.charts.load('current', { 'packages': [ 'corechart' ] });

			        google.charts.setOnLoadCallback( function () 
					{
	  					var data = new google.visualization.DataTable();
	  					data.addColumn('string', 'app');
	  					data.addColumn('number', 'flops');
		
						// populate the dataTable
	  					<x:apply-templates mode="dataTable" />

						var chart = new google.visualization.PieChart(document.getElementById('chart_div'));
						chart.draw(
							data, 
							{	// chart options
								'title': 'Cluster Utilization'
							} );
					} );					
				</script>
			</head>
			<body>
				<x:apply-templates />
			</body>
		</html>
	</x:template>
	
	<!-- populate the data table -->
	<x:template match="boinc_cluster_state" mode="dataTable">
		<!-- across all apps that have an active task -->
		<x:for-each select="set:distinct(//result[active_task]/../app)">
			data.addRow( [
				'<x:value-of select="user_friendly_name" />' ,
				<x:value-of select="sum(//app_version[app_name = current()/name]/flops) div 1000000"/>
				] );			
		</x:for-each>
	</x:template>	

	<x:template match="boinc_cluster_state">
		<div><x:value-of select="@created" /></div>
		<table>
			<tr>
				<td><div id="chart_div"/></td>
				<td>
					<table id="boinc_cluster_state">
						<tr>
							<th>App</th>
							<th>Project</th>
							<th>Node</th>
							<th/>
						</tr>
						<x:apply-templates select="boinc_client/boinc_gui_rpc_reply/client_state/result">
							<x:sort select="name" /> <!-- to group the same apps together -->
						</x:apply-templates>
					</table>
				</td>
			</tr>
		</table>
	</x:template>

	<!-- results with active tasks -->
	<x:template match="result[active_task]">
		<!-- get related structs -->
		<x:variable name="project"      select="../project[master_url = current()/project_url]" />
		<x:variable name="workunit"     select="../workunit[name = current()/wu_name]" />
		<x:variable name="app_version"  select="../app_version[app_name = $workunit/app_name]" />
		<x:variable name="app"          select="../app[name = $workunit/app_name]" />
		<tr>
			<td>
				<x:value-of select="$app/user_friendly_name" /> 
			</td>
			<td>
				<x:value-of select="$project/project_name" /> 
			</td>
			<td>
				<x:value-of select="../host_info/domain_name" />				
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
	<x:template match="text()" mode="dataTable" />	

</x:stylesheet>
