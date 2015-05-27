#!/bin/bash

#################
#tool for dotcms-inspectoring sys, db, and dotcms specific info for analysis
#v 0.1
#Matt Yarbrough
#dotCMS
###################
#TODO: 	ability to turn off certain subscripts
#	push publish config
#	cachestats using setup from Chris McCracken or REST API
#	db threads
# 	db locks
#	use mktemp for setup of log storage space
#	/proc/${PID}/smaps, /proc/${PID}/status, and /proc/${PID}/stat

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

for install in $(ps aux | grep java | grep dotserver | grep org.apache.catalina.startup.Bootstrap | awk '{ print $2 }'); do

DOTPROCPID=$install
DOTOWNER=$(ps aux | grep -v grep | grep $install | awk '{ print $1}')

if [ ! -d logs-$DOTPROCPID ]; then
    mkdir -p logs-$DOTPROCPID;
fi;
getCatHome1=$(ps ax | grep $install)
getCatHome2=${getCatHome1#*\Dcatalina.home=}
getCatHome3=${getCatHome2%%/tomcat*}
DOTHOME=$( echo "${getCatHome3}" | sed -e "s/^\ *//g" -e "s/\ *$//g")
#ADMINUSER=$2
#ADMINPASS=$3
HOSTNAME=$(hostname)
TOMCATVERSION=${DOTHOME#*\dotserver\/}
RUNDATE=$(date +"%Y%m%d-%H%M%S")
LOGFOLDER=logs-$DOTPROCPID
SYSLOGFILE=$LOGFOLDER/di-system-$HOSTNAME-$RUNDATE.txt
DOTLOGFILE=$LOGFOLDER/di-dotcms-$HOSTNAME-$RUNDATE.txt
#DB info commented, we aren't using this information right now and I'd rather not be grabbing credentials unnecessarily
#DBX=$(grep username="*" $DOTHOME/dotCMS/META-INF/context.xml | grep -v 'username="{your db user}"' | grep -v 'username="{your user}@{your server}"')
#DBU1=${DBX#*\"}
#DBUSER=${DBU1%\"\ pa*}
#DBP1=${DBX#*word=\"}
#DBPASS=${DBP1%\"\ maxAc*}

if [ skipTee != true ]
	then 
		exec &> >(tee -a "$SYSLOGFILE")
	else
		exec > $SYSLOGFILE 2>&1
fi

echo "dotCMS Inspector Run: " $RUNDATE 
echo "JAVA_HOME: " $JAVA_HOME

#SYSTEM FUNCTIONS
function getDB {
	#what database are we?
	echo -e  "\n\n##### DATABASE INFORMATION #####"
	PG="$(grep '<\!--\ POSTGRESQL -->' $tomcat/conf/Catalina/localhost/ROOT.xml)"
	MY="$(grep '<\!--\ MYSQL UTF8 -->' $tomcat/conf/Catalina/localhost/ROOT.xml)"

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
	ls $DOTHOME/dotCMS/WEB-INF/lib/dotcms*jar
}

function getJVMInfo {
	echo -e "\n# JVM INFORMATION AND MEMORY ALLOCATION:" 
	sudo -u dotcms jps -v
}

function getDotCMSMem {
	echo -e "\n# Memory Info:" 
	echo $DOTPROCPID  | xargs ps -o rss,sz,vsz
}

function getIndexList {
	echo -e "\n# List Indexes:"
	ls -l $DOTHOME/dotCMS/dotsecure/esdata/dotCMSContentIndex/nodes/*/indices
	echo -e "\n# Index Content Volume:"
	find $DOTHOME/dotCMS/dotsecure/esdata/dotCMSContentIndex/nodes/ | wc -l
}

function getConfigFiles {
	echo -e "\n# Config and log are located in the logs folder" 

	cp $DOTHOME/dotCMS/WEB-INF/classes/dotmarketing-config.properties $LOGFOLDER

	cp $DOTHOME/dotCMS/WEB-INF/classes/portal.properties $LOGFOLDER
	
	cp $DOTHOME/conf/server.xml $LOGFOLDER

	cp $DOTHOME/tomcat/logs/dotcms.log  $LOGFOLDER
	
	cp $DOTHOME/dotCMS/WEB-INF/web.xml $LOGFOLDER
	
}

function getPlugins {
	#find -f on plugins, maybe tarball them, exclude build folder
	echo -e "\n# Static Plugins:" 
	ls  $DOTHOME/dotCMS/WEB-INF/lib
	echo -e "\n# Dynamic Plugins: "
	ls $DOTHOME/dotCMS/WEB-INF/felix/load
}

function getJavaDump {
	#this should loop several times to get an idea of what's really going on
	echo -e "\n#Java thread dump located at logs/javadump.txt" 
	PID=$(pgrep -o -x java)
	sudo -u $DOTOWNER jstack $PID >> $LOGFOLDER/javadump.txt
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
	ls -l $DOTHOME/dotCMS/assets 
	
}

function getGCInfo {
	#java opts lists gc log name
	echo -e "\n# GC Info:"

	if [ -f $DOTHOME/dotCMS/dotsecure/logs/*gc*.log ]; then

	cp $DOTHOME/dotCMS/dotsecure/logs/*gc*.log $LOGFOLDER

	else
		echo "no GC log in $DOTHOME/dotCMS/dotsecure/logs/"
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
#getPushConfig
#getCacheStats
getAssetsInfo
getGCInfo

tar -czf "di-$HOSTNAME-PROC$DOTPROCPID-$RUNDATE.tgz" $LOGFOLDER

rm -Rf $LOGFOLDER

done
exit
