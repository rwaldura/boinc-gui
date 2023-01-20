#!/bin/sh

cat << _HTTP_
Content-type: application/json; charset=UTF-8

_HTTP_

exec ./get-data-table.json
