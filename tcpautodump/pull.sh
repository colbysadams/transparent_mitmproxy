#!/usr/bin/env bash



files=`adb shell "ls /sdcard/tcpautodump_*"`


arr=($files)

if (( ${#arr[@]} == 0 )); then
    echo "no tcpautodump files to pull..."
    exit 1
fi

file1=${arr[0]}

filename=$(basename -- "$file1")

extension="${filename##*.}"
output_dir="${filename%.*}" 

    
mkdir "$output_dir"

for file in $files; do
    adb pull "$file" "$output_dir"
    adb shell "rm -f $file"
done

echo ""
echo "${#arr[@]} pcap files have been placed in ./$output_dir/"
