#!/bin/bash

echo -e "\n# GC Info:"

if [ -f $DOTHOME/webapps/ROOT/dotsecure/logs/*gc*.log ]; then

cp $DOTHOME/webapps/ROOT/dotsecure/logs/*gc*.log 

else
	echo "no GC log in $DOTHOME/webapps/ROOT/dotsecure/logs/"
fi

 
