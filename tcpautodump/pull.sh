#!/usr/bin/env bash



files=`adb shell "ls /sdcard/tcpautodump_*"`

device=`adb shell getprop ro.product.model | sed 's/ /_/g'`

arr=($files)

if (( ${#arr[@]} == 0 )); then
    echo "no tcpautodump files to pull..."
    exit 1
fi

file1=${arr[0]}

CLEAN=${device// /_}

CLEAN=${CLEAN//[^a-zA-Z0-9_]/}


filename=$(basename -- "$file1")
extension="${filename##*.}"
output_dir="${filename%.*}_${CLEAN}" 

    
mkdir "$output_dir"
count=0
for file in $files; do
    file=${file//[^a-zA-Z0-9_\/\.\-]/}
    filename=$(basename -- "$file")
    adb pull "$file" "${output_dir}/${CLEAN}_${filename}"
    if [ $? -eq 0 ]; then
        let count++
        adb shell "rm -f $file"
    else
        echo "failed to pull file: ${file}"
        echo " skipping... the file will not be removed from the device"
    fi
done

echo ""
echo "${count} pcap files have been placed in ./$output_dir/"
