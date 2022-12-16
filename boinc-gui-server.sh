#!/bin/zsh
##############################################################################
#
# Replace stdin with an _authenticated_ channel to a BOINC GUI server.
# This channel is open for output only, i.e. it can be written to. It is used
# to send requests to a BOINC client.
# The output of this program, is the response of the BOINC client.
#
# Example:
# $ echo "<get_state/>\003" | boinc-gui-server.sh host.example.com > response.xml
#
# Authentication protocol is defined at 
# http://boinc.berkeley.edu/trac/wiki/GuiRpcProtocol 
#
##############################################################################

zmodload zsh/net/tcp

readonly RPC_HOST=$1
readonly RPC_PORT=31416
readonly RPC_PASSWORD=aoeu0
readonly RPC_REQUEST=$2
readonly RPC_ETX=\\003 # control character used by BOINC GUI RPC

##############################################################################
debug()
{
	[[ "$DEBUG" ]] && print -u2 "++ $@"
}

##############################################################################
request()
{
	print -u$RPC_SERVER "
<boinc_gui_rpc_request>
$1
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
	nonce=$( expr "$line" : '<nonce>\([0-9]*\.[0-9]*\)')
	debug "nonce=$nonce"
	
	read -u$RPC_SERVER line # should be "</boinc_gui_rpc_reply>"
	debug "1-$line"

	print "$nonce"
}

##############################################################################
auth2()
{
	nonce="$1"
	
	nonce_hash=$( md5 -q -s "$nonce$RPC_PASSWORD" )
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
# authentication protocol using file descriptor $server
# see http://boinc.berkeley.edu/trac/wiki/GuiRpcProtocol 
authenticate()
{
	auth2 $( auth1 )
	return $?
}

##############################################################################
issue()
{	
	request "<$1/>"

	# close the socket for writing:
	#exec {server}>&-
	# Unfortunately this closes the entire socket, not just for writing.
	# "exec {fd}>&-" and "exec {fd}<&-" are functionally equivalent,
	# they both close the entire fd.
	# What I need is shutdown(2) but it doesn't appear implemented in ztcp.
	# With it, I could then just: 
	#cat <&$server
	# Instead, I have to do this ugly loop:
	
	# read output from server, print to stdout
	while read -u$RPC_SERVER line
	do
		print "$line"
		[[ "$line" = '</boinc_gui_rpc_reply>' ]] && return
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
	issue "$RPC_REQUEST"
else
	print -u2 "authentication failure"
	exit 1
fi

# close all opened sockets
ztcp -c 

		