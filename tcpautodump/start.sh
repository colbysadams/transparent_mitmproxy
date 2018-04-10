#!/usr/bin/env bash


adb shell "su -c tcpdump -i any -s 0 -G 600 -C 75 -w /sdcard/tcpautodump_%Y-%m-%d_%H-%M-%S.pcap" & disown
echo ""
sleep 1
echo ""
echo "You can now unplug the phone and do whatever you need to... "

echo "To stop the capture, execute stop.sh"


