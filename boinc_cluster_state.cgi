#!/bin/sh
#
# Refresh the page every hour or so
#

cat << _HTTP_
Content-Type: text/xml; charset=UTF-8
Refresh: 3333

_HTTP_

exec ./boinc_cluster_state.xml
