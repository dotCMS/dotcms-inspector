# dotcms-inspector

This is the skeleton for the dotcms-inspector tool.  All actions are run in individual scripts, to allow for modularity.  Additional error handling can (and should) be added to each of these scripts.

Usage: Expects to run as root from /opt/dotcms/dotcms-inspector.

Coming soon:
	rewrite of db access to eliminate need to edit script
	
There is one additional script, perf.sh, which is a separate tool to run in order to get meaningful java thread dumps.
