#!/bin/sh

sqlite3 _test.db < ../schema.sql
sqlite3 _test.db < _update.sql

exit $?