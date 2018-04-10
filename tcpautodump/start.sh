#!/usr/bin/env bash

psout=`adb shell "ps | grep tcpdump"`

pids=(`sed -E "s/root\ +([0-9]+).*/\1/g" <<< "$psout"`)

if (( ${#pids[@]} > 0 )); then
    echo "tcpdump is already running on this device..."
    echo "$psout"
    echo ""
    echo -en "Are you sure you want to start a new one (q to quit):"
    read input
    if [[ $input = "q" ]] || [[ $input = "Q" ]]; then
       exit 1
    fi
fi

adb shell "su -c tcpdump -i any -s 0 -G 600 -C 75 -w /sdcard/tcpautodump_%Y-%m-%d_%H-%M-%S.pcap" & disown
echo ""
sleep 1
echo ""
echo "You can now unplug the phone and do whatever you need to... "

echo "To stop the capture, execute stop.sh"


