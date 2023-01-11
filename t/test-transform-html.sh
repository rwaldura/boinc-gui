#!/bin/sh

xsltproc ../gui.xsl _boinc_cluster_state.xml > _boinc_cluster_state.html || exit 1

num_rows=$( grep -c "dt.addRow(" _boinc_cluster_state.html )
# echo "$num_rows addRows"
test "$num_rows" -gt 1 || exit 1

num_divs=$( grep -c '<div class="progress-bar"' _boinc_cluster_state.html )
# echo "$num_divs progress bars"

test "$num_rows" -eq "$num_divs" 
exit $?