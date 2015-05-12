#!/bin/bash

#################
#tool for dotcms-inspectoring sys, db, and dotcms specific info for analysis
#v 0.1
#Matt Yarbrough
#dotCMS
#
#Requires command line arguments BASEDIR, ADMINUSER, ADPASS where BASEDIR is the path where dotcms is installed: run ./dotcms-inspector.sh /opt/dotcms/wwwroot/current admin@dotcms.com admin
###################
#
#TODO: 	ability to turn off certain subscripts
#	push publish config
#	cachestats
#	db threads
# 	db locks
#	account for other java procs
#	number of contentlets in index, ls/find of esdata maybe
#	use mktemp for setup of log storage space
#	get javahome (esp for jps cmd)
#	cachestats using jsp from Chris McCracken or REST API
#	/proc/${PID}/smaps, /proc/${PID}/status, and /proc/${PID}/stat

#GLOBALS
BASEDIR=$1
ADMINUSER=$2
ADMINPASS=$3
HOSTNAME=$(hostname)
TOMCATVERSION=$(ls $BASEDIR/dotserver)
DOTHOME=$BASEDIR/dotserver/$TOMCATVERSION
INSPECTORHOME=/opt/dotcms/dotcms-inspector
RUNDATE=$(date +"%Y%m%d-%H%M%S")
DOTPROCPID=$(pidof java)
SYSLOGFILE=logs/di-system-$HOSTNAME-$RUNDATE.txt
DOTLOGFILE=logs/di-dotcms-$HOSTNAME-$RUNDATE.txt
#DB info commented, we aren't using this information right now and I'd rather not be grabbing credentials unnecessarily
#DBX=$(grep username="*" $DOTHOME/webapps/ROOT/META-INF/context.xml | grep -v 'username="{your db user}"' | grep -v 'username="{your user}@{your server}"')
#DBU1=${DBX#*\"}
#DBUSER=${DBU1%\"\ pa*}
#DBP1=${DBX#*word=\"}
#DBPASS=${DBP1%\"\ maxAc*}

#TEST COMMANDS
command -v awk >/dev/null 2>&1 || { echo >&2 "awk is not installed.  Ending."; exit 1; }	
command -v grep >/dev/null 2>&1 || { echo >&2 "grep is not installed.  Ending."; exit 1; }	
command -v lsof >/dev/null 2>&1 || skipFileHandles=true	
command -v uname >/dev/null 2>&1 || skipOS=true	
command -v cat >/dev/null 2>&1 || skipOS=true
command -v lscpu >/dev/null 2>&1 || skipCPU=true
command -v netstat >/dev/null 2>&1 || skipNetStat=true 
command -v lspci >/dev/null 2>&1 || skipVM=true
command -v tee >/dev/null 2>&1 || skipTee=true
command -v cat >/dev/null 2>&1 ||  { DOTPROCPID=$(ps aux | grep java | grep -v grep | awk '{print $2}'); }

cd $INSPECTORHOME 

if [ ! -d logs ]; then
    mkdir logs;
fi;

if [ skipTee != true ]
	then 
		exec &> >(tee -a "$SYSLOGFILE")
	else
		exec > $SYSLOGFILE 2>&1
fi

echo "dotCMS Inspector Run: " $RUNDATE 

#SYSTEM FUNCTIONS
function getDB {
	#what database are we?
	echo -e  "\n\n##### DATABASE INFORMATION #####"
	PG="$(grep '<\!--\ POSTGRESQL -->' $DOTHOME/webapps/ROOT/META-INF/context.xml)"
	MY="$(grep '<\!--\ MYSQL UTF8 -->' $DOTHOME/webapps/ROOT/META-INF/context.xml)"

	cd utils
	if [ "$PG" ]
	  then
	    DB="POSTGRESQL"
		echo "Postgres"
	elif [ "$MY" ]
	  then
	    DB="MYSQL"
		echo "Mysql"
	else
	    DB="OTHER"
		echo "Database not supported in this script"
	fi
	cd $INSPECTORHOME
}

function getOS {
	# Courtesy of user slm on stackexchange
	echo  -e "\n# OS and Version Information:"  
	OS=`uname -s`
	REV=`uname -r`
	MACH=`uname -m`

	GetVersionFromFile()
	{
	    VERSION=`cat $1 | tr "\n" ' ' | sed s/.*VERSION.*=\ // `
	}

	if [ "${OS}" = "SunOS" ] ; then
	    OS=Solaris
	    ARCH=`uname -p` 
	    OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
	elif [ "${OS}" = "AIX" ] ; then
	    OSSTR="${OS} `oslevel` (`oslevel -r`)"
	elif [ "${OS}" = "Linux" ] ; then
	    KERNEL=`uname -r`
	    if [ -f /etc/redhat-release ] ; then
	        DIST='RedHat'
	        PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
	        REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
	    elif [ -f /etc/SuSE-release ] ; then
	        DIST=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
	        REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
	    elif [ -f /etc/mandrake-release ] ; then
	        DIST='Mandrake'
	        PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
	        REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
	    elif [ -f /etc/debian_version ] ; then
	        DIST="Debian `cat /etc/debian_version`"
	        REV=""

	    fi
	    if [ -f /etc/UnitedLinux-release ] ; then
	        DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
	    fi

	    OSSTR="${OS} ${DIST} ${REV}(${PSUEDONAME} ${KERNEL} ${MACH})"

	fi

	echo ${OSSTR}
	

}

function getMemory {
	#grep 'Mem|Cache|Swap' /proc/meminfo
	#/proc/${PID}/smaps, /proc/${PID}/status, and /proc/${PID}/stat iterate
	echo -e "\n# Total Memory:"  
	grep MemTotal /proc/meminfo | awk '{print $2}'
	echo -e "\n# Cache:"
	grep Cache /proc/meminfo | awk '{print $2}'
	echo -e "\n# Swap:"
	grep Swap /proc/meminfo | awk '{print $2}'
}

function getCPU {
	echo -e "\n# CPU Info:" 
	lscpu
	top -bn 1 | awk 'BEGIN{FS="[ \t%]+"} NR==3{ print 100-$8 }'
}

function getDiskInfo {
	echo -e "\n# Disk Info:"   
	df -h
}

function getProcs {
	echo -e "\n# PS Output:"   
	ps aux	
}

function getNetstat {
	echo -e "\n# Network Sockets:"   
	netstat -tulpn
}

function getVM {
	echo -e "\n# VM Info:" 
	lspci | grep -i vm
}

function getFileHandles {
	echo -e "\n# Open File Handles:"  
	lsof
	echo -e "\n# Network Open File Handles:"
	lsof -i
}

#EXECUTE SYSTEM FUNCTIONS
echo "\n##### SYSTEM INFORMATION #####" 
if [ skipOS != true ]
	then
		getOS
fi
getMemory
if [ skipCPU != true ]
	then
		getCPU
fi
getDiskInfo
getProcs
if [ skipNetStat != true ]
	then
		getNetStat
fi
if [ skipVM != true ]
	then
		getVM
fi		
if [ skipFileHandles != true ]
	then
	getFileHandles
fi
if [ skipTee != true ]
	then 
		exec &> >(tee -a "$DOTLOGFILE")
	else
		exec > $DOTLOGFILE 2>&1
fi

#DOTCMS FUNCTIONS
function getVersion {
	echo -e "\n# Version:" 
	ls $DOTHOME/webapps/ROOT/WEB-INF/lib/dotcms*jar
}

function getJVMInfo {
	echo -e "\n# JVM INFORMATION AND MEMORY ALLOCATION:" 
	sudo -u dotcms jps -v
}

function getDotCMSMem {
	echo -e "\n# Memory Info:" 
	pidof java  | xargs ps -o rss,sz,vsz
}

function getIndexList {
	echo -e "\n# List Indexes:"
	ls -l $DOTHOME/webapps/ROOT/dotsecure/esdata/dotCMSContentIndex_3x/nodes/*/indices
}

function getConfigFiles {
	echo -e "\n# Config and log are located in the logs folder" 

	cp $DOTHOME/webapps/ROOT/WEB-INF/classes/dotmarketing-config.properties $INSPECTORHOME/logs

	cp $DOTHOME/webapps/ROOT/WEB-INF/classes/portal.properties $INSPECTORHOME/logs
	
	cp $DOTHOME/webapps/ROOT/WEB-INF/classes/dotcms-config-cluster.properties  $INSPECTORHOME/logs

	cp $DOTHOME/conf/server.xml $INSPECTORHOME/logs

	cp $DOTHOME/webapps/ROOT/dotsecure/logs/dotcms.log  $INSPECTORHOME/logs
	
	cp $DOTHOME/conf/web.xml $INSPECTORHOME/logs
	
}

function getPlugins {
	#find -f on plugins, maybe tarball them, exclude build folder
	echo -e "\n# Static Plugins:" 
	ls  $DOTHOME/webapps/ROOT/WEB-INF/lib
	echo -e "\n# Dynamic Plugins: "
	ls $DOTHOME/webapps/ROOT/WEB-INF/felix/load
}

function getJavaDump {
	#this should loop several times to get an idea of what's really going on
	echo -e "\n#Java thread dump located at logs/javadump.txt" 
	PID=$(pgrep -o -x java)
	sudo -u dotcms jstack $PID >> $INSPECTORHOME/logs/javadump.txt
}

function getPushConfig {
	echo -e "\n# Push Info:"
	#use admin login/pw to get via API
}

function getCacheStats {
	#Version dependent, use jsp version of cache stats page (chris has one), add cmd line arg to dotcms inspector to indicate cachestats or not (default not)
	echo "\n# CacheStats:"
}

function getAssetsInfo {
	#look for asset_real_path, test writing  find ls -type f tree and write to separate file exclude dotGenerated, bundles, .zfs
	echo -e "\n# Assets Permissions:" 
	ls -l $DOTHOME/webapps/ROOT/assets 
	
}

function getGCInfo {
	#java opts lists gc log name
	echo -e "\n# GC Info:"

	if [ -f $DOTHOME/webapps/ROOT/dotsecure/logs/*gc*.log ]; then

	cp $DOTHOME/webapps/ROOT/dotsecure/logs/*gc*.log 

	else
		echo "no GC log in $DOTHOME/webapps/ROOT/dotsecure/logs/"
	fi
}

#EXECUTE DOTCMS FUNCTIONS
echo "dotCMS Inspector Run: " $RUNDATE 
echo -e "\n\n##### dotCMS INFORMATION #####" 
getVersion
getJVMInfo
getDotCMSMem
getIndexList
getConfigFiles
getPlugins
getJavaDump
getPushConfig
getCacheStats
getAssetsInfo
getGCInfo

tar -czf "di-$HOSTNAME--$RUNDATE.tgz" logs

#rm -Rf logs

exit
