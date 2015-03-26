#/bin/bash
echo -e "\n# CPU Info:" 
lscpu

top -bn 1 | awk 'BEGIN{FS="[ \t%]+"} NR==3{ print 100-$8 }'