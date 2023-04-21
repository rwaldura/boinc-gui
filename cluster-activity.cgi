#!/bin/sh

cat << _HTTP_
Content-type: application/json; charset=UTF-8
Access-Control-Allow-Origin: *

_HTTP_

# parse CGI parameters out of $QUERY_STRING and pass them along
#...

exec ./cluster-activity.json 2>/dev/null
