#!/bin/bash

wakeresp=$(piwatcher wake 10 | awk '{print $1}')
echo "PiWatcher set to reboot: $wakeresp"
watchresp=$(piwatcher watch 30 | awk '{print $1}')
echo "PiWatcher watchdog enabled: $watchresp"

while true;
do
        statusresp=$(piwatcher status)
        statusmsg=$(echo "$statusresp" | awk '{print $1}')
        if [ "$statusmsg" != 'OK' ]; then
                echo "PiWatcher error: $statusresp"
        fi
        sleep 15
done
