#!/bin/sh

#readonly DATABASE=boinc_cluster_state.db
readonly DATABASE=t/_test.db

##############################################################################
# main

# output entire document
echo 'Content-type: application/json; charset=UTF-8

{
	"cols": [ 
		{
			"id": "updated",
			"label": "Updated",
			"type": "datetime"
		},
		{
			"id": "active_task_fraction_done",
			"label": "%done",
			"type": "number"
		},
		{
			"id": "domain_name",
			"label": "Node",
			"type": "string"
		},
		{
			"id": "app_name",
			"label": "BOINC App",
			"type": "string"
		},
		{
			"id": "project_name",
			"label": "BOINC Project",
			"type": "string"
		},
		{
			"id": "mops",
			"label": "Node Power (megaops)",
			"type": "number"
		}
	],
	"rows": [ '

sqlite3 -list -noheader -newline "," "$DATABASE" "
	SELECT 
		json_object('c', 
			json_array( 
				json_object('v', strftime('Date(%Y, %m, %d, %H, %M, 0, 0)', r.updated, 'localtime')), -- off by one, unfortunately
				json_object('v', active_task_fraction_done), 
				json_object('v', domain_name),
				json_object('v', app_user_friendly_name),
				json_object('v', project_name),
				json_object('v', round((p_mfpops + p_miops) / (1000 * 1000)))
				))
	FROM 
		result r JOIN host h USING (host_cpid)
	LIMIT 3"

# conclude with an empty cell to avoid a dangling comma
echo '
		{ "c": [] }
	]
}
'

exit 0



