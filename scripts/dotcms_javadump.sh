#!/bin/bash
echo -e "\n#Java thread dump located at logs/javadump.txt" 

PID=$(pgrep -o -x java)

sudo -u dotcms jstack $PID >> $INSPECTORHOME/logs/javadump.txt
