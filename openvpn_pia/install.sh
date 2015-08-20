#!/bin/bash

# This script will install OpenVPN and 
# configure it for Private Internet Access VPN,
# including DNS leak prevention and kill switch.

# This script is intended for Raspberry Pi
# running Raspbian Wheezy.

# However, this script is for my own personal use
# only and therefore I offer no warranties.

# This script needs to be run with sudo.
# ex. sudo ./install.sh

# Update packages
apt-get update
apt-get upgrade
apt-get dist-upgrade

# Install OpenVPN
CHECK_VPN=$(dpkg -s openvpn)
if [[ $CHECK_VPN != *"Status: install ok"* ]]; then
	apt-get install openvpn
fi

# Download PIA OpenVPN config files
mkdir /etc/openvpn/pia
wget -P /etc/openvpn/pia https://www.privateinternetaccess.com/openvpn/openvpn.zip
CHECK_UNZIP=$(dpkg -s unzip)
if [[ $CHECK_UNZIP != *"Status: install ok"* ]]; then
	apt-get install unzip
fi
unzip /etc/openvpn/pia/openvpn.zip -d /etc/openvpn/pia

# Choose PIA server
cd /etc/openvpn/pia
echo ""
echo "Available servers:"
for f in *.ovpn
do
	echo "${f%%.*}"
done
echo ""
echo "Enter name of your desired PIA server from list above:"
read SERVER
cp "$SERVER.ovpn" /etc/openvpn/"$SERVER.conf"

# Enter PIA credentials and save to file "login.info"
echo ""
echo "Enter PIA login:"
read LOGIN
echo "Enter PIA password:"
read PASSWORD
cd /etc/openvpn
if ls login.info > /dev/null 2>&1; then 
	rm login.info # if login.info exists, then delete it
fi
echo $LOGIN >> login.info
echo $PASSWORD >> login.info
chmod 400 login.info

#move certificates to correct directory
mv /etc/openvpn/pia/ca.crt /etc/openvpn/ca.crt
mv /etc/openvpn/pia/crl.pem /etc/openvpn/crl.pem

# Add "login.info" to server config file
sed -i 's/auth-user-pass/auth-user-pass login.info/g' "$SERVER.conf"

# Tell OpenVPN to autostart
echo "AUTOSTART=\"$SERVER\"" >> /etc/default/openvpn

# Add PIA DNS servers to resolv.conf (DNS leak protection)
cp /etc/resolv.conf /etc/resolvconf.old
cp /home/pi/Desktop/vpnkillswitch-master/resolv.conf /etc/resolv.conf
chattr +i /etc/resolv.conf

# Download vpnkillswitch and install as service
mkdir /usr/vpnkillswitch
wget -P /usr/vpnkillswitch https://raw.githubusercontent.com/qbwaggle/rpi_scripts/master/openvpn_pia/service.sh
wget -P /usr/vpnkillswitch https://raw.githubusercontent.com/qbwaggle/rpi_scripts/master/openvpn_pia/run.sh
chmod 755 /usr/vpnkillswitch/*.sh
cp /usr/vpnkillswitch/service.sh /etc/init.d/vpnkillswitch
update-rc.d vpnkillswitch defaults

echo ""
echo "Please reboot using \"sudo reboot\" now."
