#!/bin/zsh

# Refresh the page every hour or so
<<_HTTP_
Content-Type: text/xml; charset=UTF-8
Refresh: 3333

_HTTP_

# Output the latest cluster state
basex -c =(<<'_XML_'
<commands>
	<open name="boinc" />
	<xquery>
		let $m := max( /boinc_cluster_state/@created/string() )
		return /boinc_cluster_state[@created = $m]
	</xquery>
</commands>
_XML_
) 2>/dev/null

# XQUERY db:optimize("DB", false(), map { 'attrindex': true() })
