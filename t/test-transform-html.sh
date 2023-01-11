#!/bin/sh

xsltproc ../gui.xsl _boinc_cluster_state.xml > _boinc_cluster_state.html
exit $?