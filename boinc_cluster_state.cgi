#!/bin/zsh

# the client will use this stylesheet to transform the result
readonly XSLT=gui.xsl

# Refresh the page every hour or so
<<_HTTP_
Content-Type: text/xml; charset=UTF-8
Refresh: 3333

<?xml version="1.0" encoding="UTF-8" ?>
<?xml-stylesheet href="$XSLT" type="text/xsl" ?>
_HTTP_

# Output the latest cluster state
export JAVA_ARGS=-Dorg.basex.path=/home/debian/basex
basex -d -c <( <<'_XML_'
<commands>
	<open name="boinc" />
	<xquery>
		let $m := max( /boinc_cluster_state/@created/string() )
		return /boinc_cluster_state[@created = $m]
	</xquery>
	<close />
</commands>
_XML_
)

# XQUERY db:optimize("DB", false(), map { 'attrindex': true() })
