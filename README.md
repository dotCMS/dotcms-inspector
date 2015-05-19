# dotcms-inspector

This is the skeleton for the dotcms-inspector tool.  All actions are run in individual scripts, to allow for modularity.  Additional error handling can (and should) be added to each of these scripts.

Usage:  Must be run as root. 

There is one additional script, perf.sh, which is a separate tool to run in order to get meaningful java thread dumps.

The main script sets needed variables and determines what database is running.  There are two aspects that run after this, environmental and dotcms functions.  These gather information and copy relevant files to a log directory which is subsequently packaged for transfer to another location for analysis.

Within the environmental section information is gathered to help determine if issues being experienced are the result of the environment itself.  Gathered data includes CPU, memory, disk, OS, open files, network, process, and VM information. 

Dotcms information and files packaged include version, memory usage, configuration files, gc, logs, and cache.
