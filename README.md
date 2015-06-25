# dotcms-inspector

This is a simple tool to gather information about a running dotcms instance.  Dotcms-inspector.sh is for 3.x versions, 2x-dotcms-inspector is for 2.x versions.

Usage:  Must be run as root. 

We gather a lot of system information in order to be sure that the environment is set up properly for dotCMS and to catch any unexpected behavior that may be occurring that our log files wouldn’t capture.  This includes things like what OS version is running, system memory information, number and types of CPUS, disk information including free space, all running procs and their owners, network socket statuses, open files handles, and whether this OS is running in a VM or not.

Information gathered about dotCMS installation and running process is intended to be as broad as is reasonable so that in most instances we will only need to gather information at one point in the process (note that for troubleshooting hung processes or addressing historic incidents this will not be the case).   Gathering information on the java process, including smap, status, stat, and JVM info allows us to have a solid understanding of the parent process condition.  We also gather information on the memory being used specifically by dotCMS to check possible performance issues related to memory.  Index information, config files, and information about assets all are used to assess the condition of the core functions of dotCMS.  Finally we gather java dump and garbage collection information in order to have any debugging and error information that may be useful in conjunction with the dotcms log files.
