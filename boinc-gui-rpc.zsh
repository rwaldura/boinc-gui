#!/bin/zsh
##############################################################################
#
# Manage a BOINC client, by sending a single command (a request) to its GUI
# RPC server.
# The output of this program, is the response of the BOINC client.
#
# Example:
# $ boinc-gui-rpc.sh host.example.com get_host_info > response.xml
#
# Authentication protocol is defined at 
# http://boinc.berkeley.edu/trac/wiki/GuiRpcProtocol 
#
##############################################################################

readonly RPC_PASSWORD=aoeu0
readonly RPC_HOST=${1:?"Hostname required"}
readonly RPC_PORT=31416

readonly RPC_REQUEST=${2:-get_host_info} # default request
readonly RPC_PARAM="$3" # request parameter, if any

readonly RPC_ETX=\\003 # control character used by BOINC GUI RPC

zmodload zsh/net/tcp # to create a socket

##############################################################################
debug()
{
	[[ "$DEBUG" ]] && print -u2 "++ $@"
}

##############################################################################
request()
{
	if [[ get_messages = "$1" && "$2" ]]
	then
		rpc_param="<seqno>$2</seqno>"
	fi
	
	print -u$RPC_SERVER "
<boinc_gui_rpc_request>
<$1>$rpc_param</$1>
</boinc_gui_rpc_request>$RPC_ETX"
}

##############################################################################
auth1()
{
	request '<auth1/>'

	read -u$RPC_SERVER line # should be "<boinc_gui_rpc_reply>"
	debug "1-$line"
	
	read -u$RPC_SERVER line	
	debug "1-$line"
	nonce=$( expr "$line" : '<nonce>\([0-9]*\.[0-9]*\)' )
	debug "nonce=$nonce"
	
	read -u$RPC_SERVER line # should be "</boinc_gui_rpc_reply>"
	debug "1-$line"

	print "$nonce"
}

##############################################################################
compute_hash()
{
	input="$1"
	
	if md5 </dev/null >/dev/null
	then # md5 is available (MacOS)
		md5 -q -s "$input"
	elif md5sum </dev/null >/dev/null
	then # use md5sum instead (Linux, typically)
		print -n "$input" | md5sum | cut -d ' ' -f1
	else # none 
		print -u2 "Unable to compute hash: no MD5 command available"
		exit 1
	fi		
}

##############################################################################
auth2()
{
	nonce="$1"
	
	nonce_hash=$( compute_hash "$nonce$RPC_PASSWORD" )
	debug "nonce_hash=$nonce_hash"
	
	request "<auth2> <nonce_hash>$nonce_hash</nonce_hash> </auth2>"
		
	read -u$RPC_SERVER line # should be "<boinc_gui_rpc_reply>"
	debug "2-$line"
	
	read -u$RPC_SERVER line	
	debug "2-$line"
	test "$line" = '<authorized/>'
	authorized=$?
	
	read -u$RPC_SERVER line # should be "</boinc_gui_rpc_reply>"
	debug "2-$line"
	
	return $authorized	
}

##############################################################################
# authentication protocol using file descriptor $RPC_SERVER
# see http://boinc.berkeley.edu/trac/wiki/GuiRpcProtocol 
authenticate()
{
	nonce=$( auth1 )
	auth2 "$nonce"
	return $?
}

##############################################################################
# send the request, and output its response
issue()
{	
	request "$1" "$2"

	# close the socket for writing:
	#exec {RPC_SERVER}>&-
	# Unfortunately this closes the entire socket, not just for writing.
	# "exec {fd}>&-" and "exec {fd}<&-" are functionally equivalent,
	# they both close the entire fd.
	# What I need is shutdown(2) but it doesn't appear implemented in ztcp.
	# With it, I could then just: 
	#cat <&$RPC_SERVER
	# Instead, I have to do this ugly loop:
	
	# read output from server, print to stdout
	while read -u$RPC_SERVER line
	do
		print -- "$line"
		[[ '</boinc_gui_rpc_reply>' = "$line" ]] && return
	done
}

##############################################################################
# main

# open socket to BOINC GUI RPC server
ztcp "$RPC_HOST" $RPC_PORT
readonly RPC_SERVER="$REPLY"

# authenticate using file descriptor $RPC_SERVER
if [[ "$RPC_SERVER" ]] && authenticate
then
	debug "authenticated!"
	issue "$RPC_REQUEST" "$RPC_PARAM"
else
	print -u2 "Authentication failure: aborted"
	exit 1
fi

# close all opened sockets
ztcp -c 

		
