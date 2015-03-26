#!/bin/bash
echo -e "\n#Java thread dump located at logs/javadump.txt" 

PID=$(pgrep -o -x java)

jstack $PID >> $GATHERHOME/logs/javadump.txt
