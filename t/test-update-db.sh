#!/bin/sh

sqlite3 test.db < ../schema.sql
sqlite3 test.db < _update.sql

exit $?