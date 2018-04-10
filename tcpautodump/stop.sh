#!/usr/bin/env bash


print "stopping capture..."
psout=`adb shell "ps | grep tcpdump"`

pids=`sed -E "s/root\ +([0-9]+).*/\1/g" <<< "$psout"`

for pid in $pids; do
    adb shell "su -c kill $pid"
done

echo "DONE."
echo ""
echo "To quickly pull all generated files, run the script pull.sh"
