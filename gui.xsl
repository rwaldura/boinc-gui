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
	version="1.0">

	<x:output method="html" encoding="UTF-8" />

	<x:template match="/">
		<html>
			<head>
				<link rel="stylesheet" href="styles.css" />
				<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js" />
				<script type="text/javascript">
					/*************************************************************************
					 * Troubleshooting.
					 */
					function showError(err)
					{
						console.error(err);
					}
					
					/*************************************************************************
					 * Create a XML HTTP request to retrieve JSON content.
					 */
					function newDataTableRequest(processJSON)
					{
						const xhr = new XMLHttpRequest();
						xhr.responseType = "json";
	
						xhr.onerror = function(e) { showError("Error loading chart data: " + e) };

						xhr.onload = function() {
							console.log("XHR: load status=" + xhr.status + " resp=" + xhr.response);
		
							if (xhr.status == 200 // HTTP OK
								&amp;&amp; xhr.response) { // JSON parsed successfully
								console.log("XHR: chart data loaded, calling JSON handler");
								processJSON(xhr.response);
							} else {
								showError("XHR: probable JSON parsing error loading chart data: status=" + xhr.status + " resp=" + xhr.response);
							}
						};

						return xhr;
					}
					
					/*************************************************************************
					 * Called once the XML HTTP request completes. 
					 */
					function updateChart(json)
					{
						const time_chart_div = document.getElementById('time_chart_div');
					
						try {
							const dt = new google.visualization.DataTable(json);
							dt.sort(0); // order rows by day
							// columns are already ordered alphabetically
													
							<!-- const chart1 = new google.visualization.Table(time_chart_div); -->
							<!-- const chart1 = new google.visualization.ColumnChart(time_chart_div); -->
							const chart1 = new google.visualization.AreaChart(time_chart_div);
							chart1.draw(
								dt, 
								{	// chart options
									fontName: "Arial", // matches styles.css
							        isStacked: true,
									// slanted dates on horizontal axis
									hAxis: { slantedText: true, slantedTextAngle: 30 }
								} );
						} catch (e) {
							showError("Drawing charts: " + e);
						}	
					}
					
					/*************************************************************************
					 * Retrieve JSON data for this time-based chart, then draw it.
					 */
					function loadTimeChartData(url = "get-data-table.cgi")
					{
						const request = newDataTableRequest(updateChart /* func called once request completes */);
						request.open("GET", url, true /* async */);
						request.send();
						console.log("requested " + url);
						// updateChart is called next
					}
					
					/*************************************************************************
					 * main
					 */
			        google.charts.load('current', { 'packages': [ 'corechart', 'table' ] });

			        google.charts.setOnLoadCallback( function () {
	  					const dt = new google.visualization.DataTable();
	  					/* 0 */ dt.addColumn('string', 'result');
	  					/* 1 */ dt.addColumn('string', 'app');
	  					/* 2 */ dt.addColumn('string', 'app_long');
	  					/* 3 */ dt.addColumn('string', 'project');
	  					/* 4 */ dt.addColumn('string', 'host');
	  					/* 5 */ dt.addColumn('number', 'ops');
		
						// populate the dt datatable
	  					<x:apply-templates mode="dataTable" />

						// SELECT app, COUNT(*) AS n FROM dt GROUP BY app
						// https://developers.google.com/chart/interactive/docs/reference#google_visualization_data_group
						const grouped = google.visualization.data.group(
							dt,
							[ 3, 2 ], // group by "project" and "app_long" columns
							[ { column: 0, aggregation: google.visualization.data.count, type: 'number' } ] );
						// ORDER BY project
						grouped.sort(0);
						
						// hide column 0: project name; it was only used for ordering purposes
						const dv = new google.visualization.DataView(grouped);
						dv.hideColumns([0]);

						const chart = new google.visualization.PieChart( document.getElementById('pie_chart_div') );
						chart.draw(
							dv, 
							{	// chart options
								fontName: "Arial", // matches styles.css
								pieHole: 0.4,
							} );
							
						loadTimeChartData(); ("t/_data-table.json");
					} );					
				</script>
			</head>
			<body>
				<div id="top_left">
					<div id="pie_chart_div"/> <!-- pie chart -->
					<div class="vertical_chart_title">Instant Cluster Activity</div>
				</div>
				<div id="top_right">
					<x:apply-templates mode="html" />
				</div>
				<div id="bot_left">
					<div class="chart_title">Past Cluster Activity</div>
					<div id="time_chart_div">
						<p><i>loading...</i></p>
					</div> 
				</div>
			</body>
		</html>
	</x:template>

	<!-- ************************************************************************
		Create data table. 
	-->	
	<!-- results with active tasks in processing state -->
	<x:template match="result[active_task/active_task_state = 1]" mode="dataTable">
		<!-- get related structs -->
		<x:variable name="project"     select="../project[master_url = current()/project_url]" />
		<x:variable name="workunit"    select="../workunit[name = current()/wu_name]" />
		<x:variable name="app_version" select="../app_version[app_name = $workunit/app_name]" />
		<x:variable name="app"         select="../app[name = $workunit/app_name]" />
		<x:variable name="host"        select="../host_info" />
		dt.addRow( [
			/* 0: result      */ '<x:value-of select="name" />',
			/* 1: app (short) */ '<x:value-of select="$app/name" />',
			/* 2: app (long)  */ '<x:value-of select="$app/user_friendly_name" /> – <x:value-of select="$project/project_name" />',
			/* 3: project     */ '<x:value-of select="$project/project_name" />',
			/* 4: host        */ '<x:value-of select="$host/domain_name" />',
			/* 5: ops         */ <x:value-of select="round(($host/p_fpops + $host/p_iops) div (100 * 1000 * 1000))" />
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
				<x:sort select="../project[master_url = current()/project_url]/project_name" /> <!-- ordered by project -->
				<x:sort select="../host_info/domain_name" />
			</x:apply-templates>
		</table>
		<div class="note">
			<p>Updated <x:value-of select="@created" /></p>
		</div>		
	</x:template>

	<!-- results with tasks actively executing -->
	<x:template match="result[active_task/active_task_state = 1]" mode="html">
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
