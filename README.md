HTML GUI for BOINC cluster.

# Design
1. Collect state from each cluster node
	1. Execute `get_state` RPC to each cluster node, store result temporarily
1. Assemble these states into one big XML document
	1. this is `boinc_cluster_state.xml`
1. Serve this document to the client
	1. this is `boinc_cluster_state.cgi`
1. Client transforms this XML data into HTML with a XSL transform (a.k.a stylesheet)
	1. See `gui.xsl`
	

# References

See also
- https://boinc.berkeley.edu/trac/wiki/GuiRpcProtocol#get_state
- https://developer.mozilla.org/en-US/docs/Web/EXSLT

