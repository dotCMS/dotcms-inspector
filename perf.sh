#make dotcms home, log path variable

export TIMESTAMP=$(date +%Y%m%d%H%M%S)
    echo "Thread CPU stats for Dotcms process $(cat /var/run/dotcms/dotcms.pid)" >>/opt/dotcms/wwwroot/current/tomcat/logs/thread_cpu_$(hostname -s)_$TIMESTAMP.txt
    echo -n " Memory: " >>/opt/dotcms/wwwroot/current/tomcat/logs/thread_cpu_$(hostname -s)_$TIMESTAMP.txt
    ps --pid $(cat /var/run/dotcms/dotcms.pid) -o rss |grep -E "^\s*[0-9]+" | xargs -i% echo "% / 1024" | bc | xargs printf "%s MB\n" >>/opt/dotcms/wwwroot/current/tomcat/logs/thread_cpu_$(hostname -s)_$TIMESTAMP.txt
    echo -n " Threads: " >>/opt/dotcms/wwwroot/current/tomcat/logs/thread_cpu_$(hostname -s)_$TIMESTAMP.txt
    ps --pid $(cat /var/run/dotcms/dotcms.pid) -o nlwp |grep -E "^\s*[0-9]+" >>/opt/dotcms/wwwroot/current/tomcat/logs/thread_cpu_$(hostname -s)_$TIMESTAMP.txt
    echo "TID     %CPU    CPUTIME" >>/opt/dotcms/wwwroot/current/tomcat/logs/thread_cpu_$(hostname -s)_$TIMESTAMP.txt
    ps --pid $(cat /var/run/dotcms/dotcms.pid) -L -o tid,pcpu,cputime |grep -E "^\s*[0-9]+" |sort -rn -k 2 |xargs -n 3 printf '0x%x\t%s\t%s\n' >>/opt/dotcms/wwwroot/current/tomcat/logs/thread_cpu_$(hostname -s)_$TIMESTAMP.txt
$JAVA_HOME/bin/jstack -l $(cat /var/run/dotcms/dotcms.pid) > /opt/dotcms/wwwroot/current/tomcat/logs/threaddump_$(hostname -s)_$TIMESTAMP.txt
echo $TIMESTAMP
