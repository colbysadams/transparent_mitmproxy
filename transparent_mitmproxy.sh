#!/bin/bash


##########################################
# CONFIG VARIABLES
defaultInterface="en0"
defaultDNS="8.8.8.8"


##########################################
#if not root, try to get root permissions
if [ "$EUID" -ne 0 ]; then

    echo "root permissions required..."
    echo "Attempting to run as root..."
    exec sudo bash "$0" "$@"
    exit 0;
else    
    ##############################################
    # This will allow all users to run pfctl -s state
    # This is required to run mitmproxy in transparent mode
    if [ `cat /etc/sudoers | grep -c "ALL ALL=NOPASSWD: /sbin/pfctl -s state"` -eq 0 ]; then
        echo "giving current user passwordless root permissions..."
        echo "Required to run mitmproxy in transparent mode"
        echo 'ALL ALL=NOPASSWD: /sbin/pfctl -s state' >> /etc/sudoers
    else 
        echo "Required permissions already granted"
    fi
fi   

########################################
# Check if the firewall is enabled
# if firewall is not enabled, enable it and restart
firewallStatus=`defaults read /Library/Preferences/com.apple.alf globalstate`
if [ "$firewallStatus" = "0" ]; then
    
    echo "Firewall is not enabled..."
    echo "Please go to settings and enable the firewall under Security & Privacy"
    exit 1

fi

echo 

######################################
# Check for any connected phones
# if present, get the ip address to display to user
phoneIP='No Phone Detected'
ipRegex="([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})" 
devicesNumber=`adb devices | grep -Ec ".+"`
if [[ "$devicesNumber" -gt "1" ]]; then
    ###########################################
    # get the sdk number for the phone
    # if sdk >= 23, we use ifconfig to get ipaddress
    # otherwise we use netcfg
    sdk=`adb shell getprop ro.build.version.sdk | tr -d '\r\n'`
    hasPhoneIP=false
    minsdk=22
    if [[ "$sdk" -gt "$minsdk" ]]; then
        echo "Phone found, SDK: $sdk"
        if [[ `adb shell ifconfig wlan0 | grep 'inet addr:'` =~ $ipRegex ]]; then
            phoneIP="${BASH_REMATCH[1]}"
            hasPhoneIP=true
            echo "got the ip address for phone: $phoneIP"
        fi
    else 
        echo "phone found, SDK: $sdk"
        if [[ `adb shell netcfg | grep wlan0` =~ $ipRegex ]]; then
            phoneIP="${BASH_REMATCH[1]}"
            hasPhoneIP=true
            echo "got the ip address for phone: $phoneIP"
        fi
    fi
fi


########################################
# get the interface for wifi on this computer
compIP='Use current computer IP address'
interfaceRegex="Hardware Port: Wi-Fi, Device: (.{1,5}[0-9])"

interface_list=`networksetup -listnetworkserviceorder`

if [[ `networksetup -listnetworkserviceorder` =~ $interfaceRegex ]]; then
    interface="${BASH_REMATCH[1]}"
    echo "Found Wi-Fi interface: ${interface}"
else 
    #try default interface
    interface="$defaultInterface"
fi
#######################################
# get the ip address of this computer
hasComputerIP=false
if [[ `ifconfig $interface | grep 'inet '` =~ $ipRegex ]]; then
    computerIP="${BASH_REMATCH[1]}"
    echo "computer ip: $computerIP"
    hasComputerIP=true
fi 

#######################################
# ipSameLen is the shared char of ipaddresses
ipDiff=`printf "%s\n" "$computerIP" "$phoneIP" | sed -e 'N;s/^\(.*\).*\n\1.*$/\1/'`
ipSameLen=${#ipDiff}
if [[ "$ipSameLen" -lt "9" ]]; then
    echo "############################################################"
    echo "ARE YOUR COMPUTER AND PHONE ON THE SAME WIFI NETWORK?"
    echo "This wont work if you're on the wrong network"
    echo "Phone IP: $phoneIP"
    echo "Computer IP: $computerIP"
    read -p "If you know you're on the correct network, press enter (ctrl-c to quit):"
fi

#########################################
# Create some files and such
fileDirectory=`pwd`
backupFile="$fileDirectory/oopsies.flow"
configFile="$fileDirectory/pf.conf"

if [ ! -d "$fileDirectory" ]; then
    mkdir "$fileDirectory"
fi



######################################
#print helpful info
echo
echo
echo "##########################################################"
echo "Go to wifi settings on the phone"
echo "##########################################################"
echo  
echo "##########################################################"
echo "1. open advanced settings by holding down name of network" 
echo "  >>>  show advanced settings"
echo 2. change DHCP to static
echo 
echo "3. Set the phone ipaddress:"
echo "$phoneIP"
echo 
echo 4. Set the gateway ip address: 
echo "$computerIP"
echo 
echo 5. Set the DNS: 
echo "$defaultDNS"
echo 
echo 6. save, open browser and download cert from mitm.it
echo 
echo 7. Press enter to start mitmproxy.  You should see traffic
echo "##########################################################"
echo 
echo "##########################################################"
echo
read -p "Press enter to begin mitmproxy (ctrl-c to quit):"

#######################################
# Save the initial setting for port forwarding
# we will reset the original settings afterward
initalPortForwarding=`sudo sysctl -n net.inet.ip.forwarding`
echo "initialPortForwardingStatus= $initalPortForwarding"
if [[ "$initalPortForwarding" -eq "0" ]]; then
    sysctl -w net.inet.ip.forwarding=1
fi

function resetOnFinish() {
    sysctl -w net.inet.ip.forwarding=$initialPortForwarding   
    ###############################################################
    # on close, reset the pf.conf to the default file if applicable
    if [ -f /etc/pf.conf ]; then
        echo Resetting pf.conf to default..
        pfctl -f /etc/pf.conf >& /dev/null
    fi
}
trap resetOnFinish EXIT



######################################
#create pf.conf in user home directory if needed
echo "rdr on $interface inet proto tcp to any port 80 -> 127.0.0.1 port 8080" > $configFile 
echo "rdr on $interface inet proto tcp to any port 443 -> 127.0.0.1 port 8080" >> $configFile

######################################
# set the appropriate port forwarding rules and enable
pfctl -f "$configFile"  
pfctl -e


##############################
# actually start mitmproxy
mitmproxy -T --host 

echo "##########################################################"
echo " Cleaning up..."
##############################
# after finishing, set variables back to original values
# disable pf
pfctl -d
rm "$configFile"
echo 
echo "##########################################################"
echo "To reset the wifi on the phone, "
echo "go back to advanced settingg and change static to DHCP"
echo "##########################################################"


