#!/bin/bash
echo -e "\n# Total Memory:"  
grep MemTotal /proc/meminfo | awk '{print $2}'
