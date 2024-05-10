#!/bin/zsh

DEFAULT_DAYS=33

# parse CGI parameters out of $QUERY_STRING
# strip all non-digits, such that "a=1&b=2&c=3" becomes "123"
days=$( tr -d -c 0123456789 <<<$QUERY_STRING )

cat << _HTTP_
Content-type: application/json; charset=UTF-8
Access-Control-Allow-Origin: *

_HTTP_

exec ./cluster-activity.json ${days:-$DEFAULT_DAYS} 2>/dev/null
