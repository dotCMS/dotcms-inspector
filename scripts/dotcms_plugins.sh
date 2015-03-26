#!/bin/bash
echo -e "\n# Static Plugins:" 

ls  $DOTHOME/webapps/ROOT/WEB-INF/lib

echo -e "\n# Dynamic Plugins: "
ls $DOTHOME/webapps/ROOT/WEB-INF/felix/load
