<x:stylesheet 
	xmlns:x="http://www.w3.org/1999/XSL/Transform" 
	xmlns:set="http://exslt.org/sets"
	version="1.0">

	<x:output method="html" encoding="UTF-8" />

	<x:template match="/">
		<html>
			<head/>
			<body>
				<x:apply-templates />
			</body>
		</html>
	</x:template>

	<x:template match="chapter">
		<p>title: <x:value-of select="title" /></p>
		<p>sid: <x:value-of select="sid" /></p>
		<x:variable name="sid" select="sid" />
		<p>summary: <x:value-of select="../summary[id = current()/sid]/content" /></p>
	</x:template>

	<x:template match="text()" />	

</x:stylesheet>
