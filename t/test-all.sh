#!/bin/sh

./test-dump-cluster-state.sh	&& echo "cluster-state"
./test-transform-html.sh		&& echo "transform-html"
./test-transform-sql.sh		&& echo "transform-sql"
./test-update-db.sh			&& echo "update-db"
