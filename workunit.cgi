#!/bin/zsh

# parse CGI parameters out of $QUERY_STRING
workunit_name=$QUERY_STRING

cat << _HTTP_
Content-type: text/xml; charset=UTF-8
Access-Control-Allow-Origin: *

_HTTP_

exec ./workunit.xml $workunit_name 2>/dev/null
