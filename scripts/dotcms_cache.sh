echo -e "\n# Cache copied to log folder"

tar -cvf $INSPECTORHOME/logs/cache.tar $DOTHOME/webapps/ROOT/dotsecure/h2db/*
gzip $INSPECTORHOME/logs/cache.tar
