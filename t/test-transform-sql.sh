#!/bin/sh

xsltproc ../sql.xsl _boinc_cluster_state.xml > _update.sql
exit $?