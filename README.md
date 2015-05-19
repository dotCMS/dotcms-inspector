# dotcms-inspector

This is a simple tool to gather information about a running dotcms instance.  This only works with dotcms 3.0 plus.

Usage:  Must be run as root. 

There is one additional script, perf.sh, which is a separate tool to run in order to get meaningful java thread dumps.

The main script sets needed variables and determines what database is running.  There are two aspects that run after this, environmental and dotcms functions.  These gather information and copy relevant files to a log directory which is subsequently packaged for transfer to another location for analysis.

Within the environmental section information is gathered to help determine if issues being experienced are the result of the environment itself.  Gathered data includes CPU, memory, disk, OS, open files, network, process, and VM information. 

Dotcms information and files packaged include version, memory usage, configuration files, gc, logs, and cache.
