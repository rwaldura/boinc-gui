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
		</head>
	</x:template>

	<x:template match="div[@id = 'wu_name']">
		<div class="title">
			Workunit <x:value-of select="." />
		</div>
	</x:template>

	<x:template match="table">
		<div>
			<table id="boinc_cluster_state">
				<x:apply-templates />
			</table>
		</div>
	</x:template>

	<!-- workunit result name -->
	<x:template match="TR/TD[1]">
		<td>
			<x:choose>
				<!-- when name is too long, truncate and display in full in a tooltip -->
				<x:when test="string-length(.) &gt; 16">
					<div class="tooltip">
						<x:value-of select="substring(., 1, 16)" />&hellip;
						<span class="tooltip-text"><x:value-of select="." /></span>
					</div>
				</x:when>
				<x:otherwise>
					<x:value-of select="." />
				</x:otherwise>
			</x:choose>
		</td>
	</x:template>		
	
</x:stylesheet>
