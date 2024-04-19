<?xml version="1.0" encoding="UTF-8"?>
<!--
	Convert to HTML a XML document describing the history of a workunit. 
	This present stylesheet is referenced in the
	source XML doc, and executed (processed) client-side, by the browser.
  -->

<!DOCTYPE x:stylesheet [ <!ENTITY nbsp "&#160;"> ]>

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
		<x:apply-templates />
	</x:template>

	<x:template match="table">
		<div class="title">
			Workunit <x:value-of select="TR/TD[1]" />
		</div>
		<div>
			<table id="boinc_cluster_state">
				<x:apply-templates />
			</table>
		</div>
	</x:template>

	<!-- workunit name -->
	<x:template match="TR/TH[1]">
		<x:comment>skipped</x:comment>
	</x:template>		

	<!-- workunit name, first cell of each row -->
	<x:template match="TR/TD[1]">
		<x:comment>skipped</x:comment>
	</x:template>		
	
</x:stylesheet>
