#!/bin/bash

##################
#Reconfiguration script
##################

##################
#User interactions
##################
logInfo() {
	echo "######################################"
	echo "[INFO] $1"
	echo "######################################"
}

logSuccess() {
	echo "######################################"
	echo "[SUCCESS] $1"
	echo "######################################"
}

logError() {
	echo "######################################"
	echo "[ERROR] $1" >&2
	echo "######################################"
}

##################
#Run as root
##################

if [ "$EUID" -ne 0 ]; then
	logError "Please run this script as SUDO or as ROOT"
	exit 1
fi

echo "###################"
echo "Preparing system changes"
echo "###################"

##################
#Network configuration
##################

echo ""
logInfo "Setting up YALM file and hosts file"
echo ""

##################
#find the yalm file
##################

netplanFile=""
for f in /etc/netplan/*yalm /etc/netplan/*yml; do
	if [ -f "$file" ]; then
		if grep -q "192.168.16" "$file"; then
			netplanFile="$file"
			break
		fi
	fi
done

if [ -z "netplanFile" ]; then
	logError "Cannot find netplan file"
	exit 1

logInfo "Found $netplanFile, updating IP..."
	
##################
#Back up
##################

cp "$netplanFile" "${netplanFile}.bu"

##################
#Replace IP
##################

	sed -i '/192.168.16/c\	addresses: ["192.168.16.21/24"]' "$netplanFile"
	if netplan apply; then
	logSuccess "Network updated successfully"
	else
		logError "update failed, restoring back up"
		mv "${netplanFile}.bu" "$netplanFile"
		exit 1
	fi
fi

##################
#Software Reqs
##################
echo ""
logInfo "installing Apache2 and Squid"
logInfo "updating package list"
apt update -y
logInfo "Installing softwares"
if apt install -y apache2 squid; then
	logSuccess "Software installed successfully"
else
	logError "Could not install softwares"
	exit 1
fi

##################
#Start services
##################

logInfo "Starting services"
systemctl enable apache2
systemctl start apache2
systemctl enable squid
systemctl start squid
logInfo "Both services are now started and running"

##################
#User creation
##################
echo ""
logInfo "Creating user accounts"

##################
#user creation loop
##################

for USER in dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda; do

	if id "$USER" >/dev/null 2>&1; then
	logInfo "User '$USER' already exists"
	usermod -s /bin/bash -d "/home/$USER" -m "$USER"
	else
		logInfo "Creating user: '$USER'"
		useradd -m -s /bin/bash "$USER"
	fi
	
	userHomeDir="/home/$USER"
	sshDir="$userHomeDir/.ssh"
	
##################
#Setting up SSH
##################
	mkdir -p "$sshDir"
	chmod 700 "$sshDir"
	
	if [ ! -f "$sshDir/id_rsa" ]; then
		ssh-keygen -t rsa -b 4096 -f "$sshDir/id_rsa" -N "" -q
	fi
	
	if [ ! -f "$sshDir/id_ed25519" ]; then
		ssh-keygen -t ed25519 -f "$sshDir/id_ed25519" -N "" -q
	fi
	
	cat "$sshDir/id_rsa.pub" > "$sshDir/authorized_keys"
	cat "$sshDir/id_ed25519.pub" >> "$sshDir/authorized_keys"
	
	chmod 600 "$sshDir/authorized_keys"
	chown -R "$USER:$USER" "$sshDir"
done

logSuccess "All user accounts and ssh configurations created"

##################
#User dennis stuff
##################

echo ""

logInfo "Setting up elevated access for user dennis"

if usermod -aG sudo dennis; then
	logSuccess "User dennis added to sudo"
else
	logError "Adding dennis to sudo failed"
	exit 1
fi

##################
#Setting up SSH key for dennis
##################
dennisKey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt990x5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

if ! grep -q "$dennisKey" /home/dennis/.ssh/authorized_keys; then
	echo "$dennisKey" >> /home/dennis/.ssh/authorized_keys
else
	logInfo "key already exists"
fi

echo ""
echo "#################################################"
logSuccess "Tasks run successfuly"
echo "#################################################"




