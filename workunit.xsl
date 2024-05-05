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
				Workunit <x:value-of select="../body/div[@id = 'wu_name']" />
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
			<th>Result</th> 	<!--  1 -->
			<th>Recorded</th> 	<!--  2 -->
			<th>State</th> 		<!--  3 -->
			<th>Task</th> 		<!--  4 -->
			<th>% done</th> 	<!--  5 -->
			<th>Remaining</th> 	<!--  6 -->
			<th>Elapsed</th> 	<!--  7 -->
			<th>Exit Code</th> 	<!--  8 -->
			<!-- app name --> 	<!--  9 -->
			<!-- hostname -->	<!-- 10 -->
			<th>Received</th> 	<!-- 11 -->
			<th>Completed</th> 	<!-- 12 -->
			<th>Reported</th> 	<!-- 13 -->
		</tr>
	</x:template>		

	<!-- workunit result name -->
	<x:template match="TR/TD[1]">
		<td>
			<x:choose>
				<!-- when name is too long, truncate and display in full in a tooltip -->
				<x:when test="string-length(.) &gt; 32">
					<div class="tooltip">
						<x:value-of select="substring(., 1, 32)" />&hellip;
						<span class="tooltip-text"><x:value-of select="." /></span>
					</div>
				</x:when>
				<x:otherwise>
					<x:value-of select="." />
				</x:otherwise>
			</x:choose>
		</td>
	</x:template>		

	<!-- drop some columns -->
	<x:template match="TR/TD[9]" />
	<x:template match="TR/TD[10]" />
	<x:template match="TR/TD[14]" />
	<x:template match="TR/TD[15]" />
	<x:template match="TR/TD[16]" />
	
</x:stylesheet>
