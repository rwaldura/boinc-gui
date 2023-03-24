HTML GUI for BOINC cluster.

# Design
1. Collect state from each cluster node, store it into a SQL database
	1. Hourly, execute `get_state` RPC to each cluster node — see `boinc_cluster_state.xml`
	1. BOINC RPCs return XML; process this XML to SQL — see `sql.xsl`
1. Browsers inspect cluster state at will, by requesting `boinc_cluster_state.cgi`
	1. Calls `boinc_cluster_state.xml`
1. Browser transforms this XML data into HTML — see `gui.xsl`
1. Browser also uses a CSS stylesheet to beautify the results: `styles.css`

# Dependencies
1. SQLite 3
1. `xsltproc` XSLT 1.0 processor
1. HTTP server: I use `mini_httpd`, but I'm sure Apache could do
1. `zsh` 

# See Also
- https://boinc.berkeley.edu/trac/wiki/GuiRpcProtocol
- https://developer.mozilla.org/en-US/docs/Web/EXSLT
