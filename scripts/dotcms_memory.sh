#!/bin/bash

echo -e "\n# Memory Info:" 
pidof java  | xargs ps -o rss,sz,vsz
