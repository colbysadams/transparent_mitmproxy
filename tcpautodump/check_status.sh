#!/usr/bin/env bash


echo "Sniffing for dumps..."
psout=`adb shell "ps | grep tcpdump"`

pids=`sed -E "s/root\ +([0-9]+).*/\1/g" <<< "$psout"`

count=0
for pid in $pids; do
    let count++
done

if [ $count -eq 0 ];then
    echo "$count"
    echo "No tcpdumps being taken... smells nice"
else
    echo "There are $count tcpdumps being taken."
fi
echo ""
