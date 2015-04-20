#!/bin/bash

#################
#tool for dotcms-inspectoring sys, db, and dotcms specific info for analysis
#v 0.1
#Matt Yarbrough
#dotCMS
#
#To run set the variables DBNAME, DBUSER, and DBPASS then execute the script as root
###################
#
#TODO: 	ability to turn off certain subscripts
#	push publish config
#	cachestats
#	db threads
# 	db locks
#	get db information from context.xml instead of command line (parse where variables are not the default)
#	include pid of dotcms for cross references
#	close db conns
#	echo output to console as well as file
#	use tar -cvzf to a .tgz
#	add hostname to start of file to differentiate nodes, cluster info from db


#VARIABLES TO SET
DBNAME=dot256
DBUSER=dev
DBPASS=w03m

#Globals
HOSTNAME=$(hostname)
DOTHOME=/opt/dotcms/wwwroot/current/dotserver/tomcat-7.0.54
INSPECTORHOME=/opt/dotcms/dotcms-inspector
RUNDATE=$(date +"%Y%m%d-%H%M%S")
SYSLOGFILE=$INSPECTORHOME/logs/di-system-$HOSTNAME-$RUNDATE.txt
DOTLOGFILE=$INSPECTORHOME/logs/di-dotcms-$HOSTNAME-$RUNDATE.txt
export CLASSPATH=.:$INSPECTORHOME/utils:$INSPECTORHOME/utils/mysql-connector-java-5.1.35-bin.jar:$INSPECTORHOME/utils/postgresql-9.4-1201.jdbc4.jar
cd $INSPECTORHOME

exec > $SYSLOGFILE 2>&1
echo "dotCMS Inspector Run: " $RUNDATE 

#what database are we?
echo -e  "\n\n##### DATABASE INFORMATION #####"
PG="$(grep '<\!--\ POSTGRESQL -->' $DOTHOME/webapps/ROOT/META-INF/context.xml)"
MY="$(grep '<\!--\ MYSQL UTF8 -->' $DOTHOME/webapps/ROOT/META-INF/context.xml)"

cd utils
if [ "$PG" ]
  then
    DB="POSTGRESQL"
	echo "Postgres"
	 java -cp .:./InspectPostgres.class InspectPostgres "$DBUSER" "$DBPASS" "$DBNAME" 
elif [ "$MY" ]
  then
    DB="MYSQL"
	java -cp .:./InspectMysql.class InspectMySQL "$DBUSER" "$DBPASS" "$DBNAME" 
	echo "Mysql"
else
    DB="OTHER"
	echo "Database not supported in this script"
fi
cd $INSPECTORHOME

echo "\n##### SYSTEM INFORMATION #####" 

. $INSPECTORHOME/scripts/os.sh   

. $INSPECTORHOME/scripts/memory.sh 
  
. $INSPECTORHOME/scripts/swap.sh 

. $INSPECTORHOME/scripts/cpu_info.sh 

. $INSPECTORHOME/scripts/disk_info.sh 

. $INSPECTORHOME/scripts/ps.sh 

. $INSPECTORHOME/scripts/sockets.sh 
 
. $INSPECTORHOME/scripts/file_handles.sh 

. $INSPECTORHOME/scripts/vm.sh 


exec > $DOTLOGFILE 2>&1
echo "dotCMS Inspector Run: " $RUNDATE 
echo -e "\n\n##### dotCMS INFORMATION #####" 

. $INSPECTORHOME/scripts/dotcms_version.sh 

. $INSPECTORHOME/scripts/dotcms_jvm.sh 

. $INSPECTORHOME/scripts/dotcms_memory.sh 

. $INSPECTORHOME/scripts/dotcms_configfiles.sh 

. $INSPECTORHOME/scripts/dotcms_plugins.sh 

. $INSPECTORHOME/scripts/dotcms_javadump.sh 

. $INSPECTORHOME/scripts/dotcms_assets.sh 

. $INSPECTORHOME/scripts/dotcms_push.sh

. $INSPECTORHOME/scripts/dotcms_cache.sh  

. $INSPECTORHOME/scripts/dotcms_gc.sh 


#tar -czf "di-$HOSTNAME--$RUNDATE.tgz" logs

#rm -Rf logs/*

