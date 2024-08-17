<?xml version="1.0" encoding="UTF-8"?>
<!--
	Convert to HTML a XML document describing the history of a workunit. 
	This present stylesheet is referenced in the
	source XML doc, and executed (processed) client-side, by the browser.
  -->

<!DOCTYPE xsl:stylesheet [ <!ENTITY hellip "&#8230;"> ]>

<x:stylesheet 
	xmlns:x="http://www.w3.org/1999/XSL/Transform" 
	version="1.0">

	<x:output method="html" encoding="UTF-8" />

	<!-- copy input to output, unchanged -->
	<x:template match="* | text()">
		<x:copy>
			<x:apply-templates />
		</x:copy>
	</x:template> 

	<x:template match="head">
		<head>
			<link rel="stylesheet" href="styles.css" />
			<title>
				Workunit <x:value-of select="//div[@id = 'wu_name']" />
			</title>
		</head>
	</x:template>

	<x:template match="div[@id = 'wu_name']">
		<div class="title">
			Workunit <x:value-of select="." />
		</div>
	</x:template>

	<x:template match="table">
		<div>
			<p>
				<table id="boinc_cluster_state">
					<tr>
						<th>App</th>
						<td>
							<x:value-of select="TR/TD[9]" /> for:
							<a>
								<x:attribute name="href">
									<x:value-of select="TR/TD[15]" />
								</x:attribute>								
								<x:value-of select="TR/TD[14]" />
							</a>
						</td>
					</tr>
					<tr>
						<th>Running on</th>
						<td>
							<div class="tooltip">
								<x:value-of select="TR/TD[10]" />				
								<span class="tooltip-text">
									<x:value-of select="TR/TD[16]" />
								</span>
							</div>							
						</td>
					</tr>
				</table>
			</p>
		</div>
		<div>
			<h1><x:value-of select="TR/TD[1]" /></h1>
			<p>
				<table id="boinc_cluster_state">
					<tr>
						<th>Received</th>
						<td><x:value-of select="TR/TD[11]" /></td>
					</tr>
					<!-- only available once finished -->
					<x:if test="TR/TD[7] != 'NULL'">
						<tr>
							<th>Elapsed</th>
							<td><x:value-of select="TR/TD[7]" /></td>
						</tr>
						<tr>
							<th>Exit Code</th>
							<td><x:value-of select="TR/TD[8]" /></td>
						</tr>
						<tr>
							<th>Completed</th>
							<td><x:value-of select="TR/TD[12]" /></td>
						</tr>
						<tr>
							<th>Reported</th>
							<td><x:value-of select="TR/TD[13]" /></td>
						</tr>
					</x:if>
				</table>
			</p>
			<p>
				<table id="boinc_cluster_state">
					<x:apply-templates />
				</table>
			</p>
		</div>
	</x:template>

	<!-- table headers -->
	<x:template match="table/TR[1]">
		<tr>
			<th>Recorded</th> 	<!--  2 in XML -->
			<th>%done</th> 		<!--  5 -->
			<th>Remaining</th> 	<!--  6 -->
			<th>Task</th> 		<!--  4 -->
			<th>State</th> 		<!--  3 -->
			<th>Scheduler</th> 	<!-- 17 in XML -->
		</tr>
	</x:template>		

	<!-- for each row of input -->
	<x:template match="TR">
		<tr>
			<x:copy-of select="TD[ 2]" />
			<x:copy-of select="TD[ 5]" />
			<x:copy-of select="TD[ 6]" />
			<x:copy-of select="TD[ 4]" />
			<x:copy-of select="TD[ 3]" />
			<x:copy-of select="TD[17]" />
		</tr>
	</x:template>		

</x:stylesheet>
