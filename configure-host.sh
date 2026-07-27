#!/bin/bash

# ignore signals TERM HUP and INT
trap '' TERM HUP INT

# variables
VERBOSE="no"
NAME=""
IP=""
HOST_NAME=""
HOST_IP=""

# argument loop
for (( i=1; i<=$#; i++ )); do
    ARGUMENT=${!i}
    if [ "$ARGUMENT" == "-verbose" ] || [ "$ARGUMENT" == "-v" ]; then
        VERBOSE="yes"
    elif [ "$ARGUMENT" == "-name" ] || [ "$ARGUMENT" == "-n" ]; then
        i=$((i + 1))
        NAME=${!i}
    elif [ "$ARGUMENT" == "-ip" ] || [ "$ARGUMENT" == "-i" ]; then
        i=$((i + 1))
        IP=${!i}
    elif [ "$ARGUMENT" == "-hostentry" ]; then
        i=$((i + 1))
        HOST_NAME=${!i}
        i=$((i + 1))
        HOST_IP=${!i}
    fi
done

# Changing hostname
if [ "$NAME" != "" ]; then
    CURRENT_NAME=$(hostname)
    
    if [ "$CURRENT_NAME" != "$NAME" ]; then
        hostname "$NAME"
        echo "$NAME" > /etc/hostname
        sed -i "s/$CURRENT_NAME/$NAME/g" /etc/etc/hosts 2>/dev/null || sed -i "s/$CURRENT_NAME/$NAME/g" /etc/hosts
        
# Log and verbose 
        logger "configure-host.sh: changed hostname from $CURRENT_NAME to $NAME"
        if [ "$VERBOSE" == "yes" ]; then
            echo "Success: Changed hostname to $NAME"
        fi
    else
        if [ "$VERBOSE" == "yes" ]; then
            echo "Hostname is already $NAME"
        fi
    fi
fi

# Changing the IP address
if [ "$IP" != "" ]; then
    MY_INTERFACE=$(ip route show default | awk '{print $5}')
    CURRENT_IP=$(hostname -I | awk '{print $1}')
    
    if [ "$CURRENT_IP" != "$IP" ]; then
        NETPLAN_FILE=$(ls /etc/netplan/*.yaml | head -n 1)
        if [ "$NETPLAN_FILE" != "" ]; then
            sed -i "s|$CURRENT_IP/24|$IP/24|g" "$NETPLAN_FILE"
        fi
        
# modifying host file
        MY_NAME=$(hostname)
        sed -i "/$MY_NAME/d" /etc/hosts
        echo "$IP $MY_NAME" >> /etc/hosts
        
# Log and verbose        
        logger "configure-host.sh: changed IP to $IP"
        if [ "$VERBOSE" == "yes" ]; then
            echo "Success: Changed IP to $IP"
        fi
        
# Apply the IP in the background so the script does not fail
        (sleep 1; ip addr add "$IP/24" dev "$MY_INTERFACE" 2>/dev/null; ip addr del "$CURRENT_IP/24" dev "$MY_INTERFACE" 2>/dev/null) &
        
    else
        if [ "$VERBOSE" == "yes" ]; then
            echo "IP is already $IP. Doing nothing."
        fi
    fi
fi

# Host entry
if [ "$HOST_NAME" != "" ]; then
    grep -q "$HOST_IP $HOST_NAME" /etc/hosts
    if [ $? -ne 0 ]; then
        sed -i "/$HOST_NAME/d" /etc/hosts
        echo "$HOST_IP $HOST_NAME" >> /etc/hosts
# Log and verbose        
        logger "configure-host.sh: added host entry $HOST_IP $HOST_NAME"
        if [ "$VERBOSE" == "yes" ]; then
            echo "Success: Added host entry $HOST_IP $HOST_NAME"
        fi
    else
        if [ "$VERBOSE" == "yes" ]; then
            echo "Host entry $HOST_IP $HOST_NAME already exists. Doing nothing."
        fi
    fi
fi
