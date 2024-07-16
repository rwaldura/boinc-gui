#!/bin/sh
#
# Output current cluster state -- or as close to it as we can afford.
#
# This CGI program runs as another user ("nobody"). 
#

# written by update-db.sh 
readonly LATEST_STATE=/tmp/boinc_cluster_state.xml

# the browser will use this stylesheet to transform the result
readonly XSLT=gui.xsl

if head "$LATEST_STATE" 2>/dev/null | grep -q '^<?xml '
then # valid XML, let's proceed
	# Refresh the page every hour or so
	cat <<_HTTP_
Content-Type: text/xml; charset=UTF-8
Access-Control-Allow-Origin: *
Refresh: 3333

<?xml version="1.0" encoding="UTF-8" ?>
<?xml-stylesheet href="$XSLT" type="text/xsl" ?>
_HTTP_

	# skip the XML declaration
	exec tail +2 "$LATEST_STATE"
else
	cat <<_HTTP_
Content-Type: text/plain

Invalid XML file $LATEST_STATE:
_HTTP_
	head "$LATEST_STATE"
	exit 1
fi

