#!/bin/sh

./test-dump-cluster-state.sh	&& echo "OK cluster-state"
./test-transform-html.sh		&& echo "OK transform-html"
./test-transform-sql.sh		&& echo "OK transform-sql"
./test-update-db.sh			&& echo "OK update-db"
