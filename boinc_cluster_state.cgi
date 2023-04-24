#!/bin/zsh
#
# This CGI program runs as another user ("nobody"). 
# BaseX always opens the database in read+write mode.
# Therefore, the XML database must be writable by 
# "others" -- chmod o+w.
#

readonly BASEX_HOME=/home/debian/basex

# BaseX commands to output the latest document
# (must come from a file ending in .bxs)
temp=$( mktemp -t $(basename $0)-XXXXXX.bxs )
cat >$temp <<'_XML_'
<commands>
	<open name="boinc" />
	<xquery>
		let $m := max( /boinc_cluster_state/@created/string() )
		return /boinc_cluster_state[@created = $m]
	</xquery>
	<close />
</commands>
_XML_

# the browser will use this stylesheet to transform the result
readonly XSLT=gui.xsl

# Refresh the page every hour or so
<<_HTTP_
Content-Type: text/xml; charset=UTF-8
Refresh: 3333

<?xml version="1.0" encoding="UTF-8" ?>
<?xml-stylesheet href="$XSLT" type="text/xsl" ?>
_HTTP_

# Output the latest cluster state
JAVA_ARGS=-Dorg.basex.path=$BASEX_HOME basex $temp 2>/dev/null

rm $temp

# XQUERY db:optimize("DB", false(), map { 'attrindex': true() })
