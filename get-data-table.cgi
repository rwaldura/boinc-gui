#!/bin/sh

cat << _HTTP_
Content-type: application/json; charset=UTF-8

_HTTP_

# parse CGI parameters out of $QUERY_STRING and pass them along
#...

exec ./get-data-table.json
