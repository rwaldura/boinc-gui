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
 
readonly BOINC_GUI_RPC_ETX=\\003 # control character used by BOINC GUI RPC
readonly BOINC_GUI_PASSWORD=aoeu0

readonly BOINC_GUI_RPC_PORT=31416
readonly BOINC_GUI_HOST=$1

##############################################################################
debug()
{
	print -u2 "++ $@"
}

##############################################################################
auth1()
{
	server=$1
	print -u$server "
<boinc_gui_rpc_request>
	<auth1/>
</boinc_gui_rpc_request>
$BOINC_GUI_RPC_ETX"

	read -u$server line # should be "<boinc_gui_rpc_reply>"
	debug "1-$line"
	
	read -u$server line	
	debug "1-$line"
	nonce=$( expr "$line" : '<nonce>\([0-9]*\.[0-9]*\)')
	debug "nonce=$nonce"
	
	read -u$server line # should be "</boinc_gui_rpc_reply>"
	debug "1-$line"

	print "$nonce"
}

##############################################################################
auth2()
{
	server=$1
	nonce="$2"
	
	nonce_hash=$( md5 -q -s "$nonce$BOINC_GUI_PASSWORD" )
	debug "nonce_hash=$nonce_hash"
	print -u$server "
<boinc_gui_rpc_request>
	<auth2>
		<nonce_hash>$nonce_hash</nonce_hash>
	</auth2>
</boinc_gui_rpc_request>
$BOINC_GUI_RPC_ETX"
	
	read -u$server line # should be "<boinc_gui_rpc_reply>"
	debug "2-$line"
	
	read -u$server line	
	debug "2-$line"
	test "$line" = '<authorized/>'
	authorized=$?
	
	read -u$server line # should be "</boinc_gui_rpc_reply>"
	debug "2-$line"
	
	return $authorized	
}

##############################################################################
# authentication protocol using file descriptor $server
# see http://boinc.berkeley.edu/trac/wiki/GuiRpcProtocol 
authenticate()
{
	server=$1
	
	nonce=$( auth1 $server )
	debug "nonce=$nonce"

	auth2 $server "$nonce"
	return $?
}

##############################################################################
pump()
{
	server=$1
	
	# pump data present on stdin to the server
	cat >&$server

	# close the socket for writing 
	#exec {server}>&-

	# read output from server, print to stdout
	cat <&$server
}

##############################################################################
# main

# open socket to BOINC GUI server
ztcp $BOINC_GUI_HOST $BOINC_GUI_RPC_PORT
integer server=$REPLY

# authenticate using file descriptor $server
if authenticate $server
then
	debug "authenticated!"
	pump $server
else
	debug "auth failed"
fi

# close all opened sockets
ztcp -c 

		