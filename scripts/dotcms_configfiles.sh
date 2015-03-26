#!/bin/bash
echo -e "\n# Config and log are located in the logs folder" 

DOTEXT=$DOTHOME/webapps/ROOT/WEB-INF/classes/dotmarketing-config-ext.properties
PORTALEXT=$DOTHOME/webapps/ROOT/WEB-INF/classes/portal-ext.properties

cp $DOTHOME/webapps/ROOT/WEB-INF/classes/dotmarketing-config.properties $INSPECTORHOME/logs

cp $DOTHOME/webapps/ROOT/WEB-INF/classes/portal.properties $INSPECTORHOME/logs



if [ -f $DOTEXT ]; then
	cp $DOTEXT $INSPECTORHOME/logs/
else
	echo "no dotmarketing-config-ext.properties" >> $LOGFILE
fi

if [ -f $PORTALEXT ]; then
	cp $PORTALEXT $INSPECTORHOME/logs/
else
	echo "no portal-ext.properties" >> $LOGFILE
fi



cp $DOTHOME/conf/server.xml $INSPECTORHOME/logs

cp $DOTHOME/webapps/ROOT/dotsecure/logs/dotcms.log  $INSPECTORHOME/logs

