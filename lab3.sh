#!/bin/bash
# This script runs the configure-host.sh

# Check verbose mode
VERBOSE_OPTION=""
if [ "$1" == "-verbose" ] || [ "$1" == "-v" ]; then
    VERBOSE_OPTION="-verbose"
    echo "Verbose mode is enabled for deployment."
fi

# old ssh key cleanup for testing
echo "Cleaning old keys"
ssh-keygen -R server1-mgmt &>/dev/null
ssh-keygen -R server2-mgmt &>/dev/null

# SERVER 1 
echo "Transfering script to server1"
# Added connection timeout and automatic key acceptance
scp -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new configure-host.sh remoteadmin@server1-mgmt:/root
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy script to server1-mgmt" >&2
    exit 1
fi

echo "Running script on server1"
# Added connection timeout and automatic key acceptance
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new remoteadmin@server1-mgmt -- /root/configure-host.sh $VERBOSE_OPTION -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4
if [ $? -ne 0 ]; then
    echo "Error: Script failed" >&2
    exit 1
fi


# SERVER 2
echo "Transfering script to server2"
scp -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new configure-host.sh remoteadmin@server2-mgmt:/root
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy script to server2" >&2
    exit 1
fi

echo "Running script on server2"
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new remoteadmin@server2-mgmt -- /root/configure-host.sh $VERBOSE_OPTION -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3
if [ $? -ne 0 ]; then
    echo "Error: Script failed" >&2
    exit 1
fi


# --- LOCAL HOST MACHINE UPDATES ---
echo "Updating local host entry"
sudo ./configure-host.sh $VERBOSE_OPTION -hostentry loghost 192.168.16.3
if [ $? -ne 0 ]; then
    echo "Error: Failed to update local entry" >&2
    exit 1
fi

echo "Updating local host entry"
sudo ./configure-host.sh $VERBOSE_OPTION -hostentry webhost 192.168.16.4
if [ $? -ne 0 ]; then
    echo "Error: Failed to update local entry" >&2
    exit 1
fi

echo "Updated configs succesfully"
