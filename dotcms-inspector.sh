#!/bin/bash

#################
#tool for dotcms-inspectoring sys, db, and dotcms specific info for analysis
#v 0.1
#Matt Yarbrough
#dotCMS
###################

#Globals
DOTHOME=/opt/dotcms/current/dotserver/tomcat-7.0.54
INSPECTORHOME=/opt/dotcms/dotcms-inspector
RUNDATE=$(date +"%Y%m%d-%H%M%S")
LOGFILE=$INSPECTORHOME/logs/dotcms-inspector_$RUNDATE.txt


#what database are we?
PG="$(grep '<\!--\ POSTGRESQL -->' $DOTHOME/webapps/ROOT/META-INF/context.xml)"
MY="$(grep '<\!--\ MYSQL UTF8 -->' $DOTHOME/webapps/ROOT/META-INF/context.xml)"

if [ "$PG" ]
  then
    DB="POSTGRESQL"
elif [ "$MY" ]
  then
    DB="MYSQL"
else
    DB="OTHER"
fi

exec > $LOGFILE 2>&1

cd $INSPECTORHOME
echo "dotCMS Inspector: " $RUNDATE 

#
#TODO: 	ability to turn off certain subscripts
#	push publish config
#	cachestats
#	db threads
# 	db locks
#	JVM memory allocation

echo "##### SYSTEM INFORMATION #####" 

. $INSPECTORHOME/scripts/os.sh   

. $INSPECTORHOME/scripts/memory.sh 
  
. $INSPECTORHOME/scripts/swap.sh 

. $INSPECTORHOME/scripts/cpu_info.sh 

. $INSPECTORHOME/scripts/disk_info.sh 

. $INSPECTORHOME/scripts/ps.sh 

. $INSPECTORHOME/scripts/sockets.sh 
 
. $INSPECTORHOME/scripts/file_handles.sh 

. $INSPECTORHOME/scripts/vm.sh 

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

echo -e  "\n\n##### DATABASE INFORMATION #####"

. $INSPECTORHOME/scripts/db.sh 

tar -cf "dotcms-inspectoroutput-$RUNDATE.tar" logs
gzip dotcms-inspectoroutput-$RUNDATE.tar

rm -Rf logs/*

