#!/bin/bash

RGC_HOME=~/rpi-gpio-control

init_file () {
	if [ ! -f $1.orig ]; then
	sudo mv $1 $1.orig
	fi
	cp $1.orig $1
}

################################################################
## Update Raspbian
################################################################
sudo apt-get update
sudo apt-get upgrade

################################################################
## Install Wifi AP stuff
################################################################
sudo apt-get install -y dnsmasq hostapd
sudo systemctl stop dnsmasq
sudo systemctl stop hostapd
init_file /etc/dhcpcd.conf
sudo tee -a /etc/dhcpcd.conf > /dev/null << EOF
interface wlan0
	static ip_address=192.168.4.1/24
EOF
sudo service dhcpcd restart
init_file /etc/dnsmasq.conf
sudo tee /etc/dnsmasq.conf > /dev/null << EOF
interface=wlan0	# Use the require wireless interface - usually wlan0
	dhcp-range=192.168.4.10,192.168.4.200,255.255.255.0,12h
EOF
sudo tee /etc/hostapd/hostapd.conf > /dev/null << EOF
interface=wlan0
driver=nl80211
ssid=RGCAP
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=RGCAPPWD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF
init_file /etc/default/hostapd
sudo tee -a /etc/default/hostapd > /dev/null << EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF
sudo service hostapd start
sudo service dnsmasq start
init_file /etc/sysctl.conf
sudo sed -rie 's/#(net.ipv4.ip_forward=1)/\1/' /etc/sysctl.conf
sudo iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
sudo iptables-restore < /etc/iptables.ipv4.nat

################################################################
## Iceweasel + VLC plugin
################################################################
sudo apt-get install -y iceweasel browser-plugin-vlc gnash mozilla-plugin-gnash

################################################################
## RGC
################################################################
cd ~
git clone https://github.com/macherel/rpi-gpio-control.git
cd -
cd ${RGC_HOME}
git pull
cd -

################################
## /usr/bin/rpi-gpio-control
################################
sudo tee /usr/bin/rpi-gpio-control > /dev/null << EOF
#!/bin/sh

RGC_HOME=$RGC_HOME

cd \${RGC_HOME}
#export DISPLAY=":0.0"
python rpi-gpio-control.py config.json
cd -
EOF
sudo chmod +x /usr/bin/rpi-gpio-control

################################
## /etc/init.d/rpi-gpio-control
################################

sudo tee /etc/init.d/rpi-gpio-control > /dev/null << EOF
#! /bin/sh
# /etc/init.d/rpi-gpio-control

### BEGIN INIT INFO
# Provides: rpi-gpio-control
# Required-Start:    \$network \$local_fs
# Required-Stop:     \$network \$local_fs
# Default-Start:     4 5
# Default-Stop:      0 1 2 3 6
# Short-Description: rpi-gpio-control init script.
# Description: Starts and stops rpi-gpio-control services.
### END INIT INFO

#VAR
RGC_HOME=$RGC_HOME
RUN="/usr/bin/rpi-gpio-control"
RGC_PID=\$(ps aux | awk '/python rpi-gpio-control/ && !/awk/ {print \$2}')

start() {
	echo "Starting script rpi-gpio-control"
	if [ -z "\$RGC_PID" ]; then
		(nohup \$RUN) > \$RGC_HOME/rpi-gpio-control.log 2>&1 &
		echo "Started"
	else
		echo "rpi-gpio-control already started"
	fi
}
stop() {
	echo "Stopping script rpi-gpio-control"
	if [ ! -z "\$RGC_PID" ]; then
		kill -9 \$RGC_PID
	fi
	echo "OK"
}
status() {
	if [ ! -z "\$RGC_PID" ]; then
		echo "rpi-gpio-control is running with PID = "\$RGC_PID
	else
		echo "No process found for RGC"
	fi
}

# Carry out specific functions when asked to by the system
case "\$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	restart)
		stop
		start
		;;
	status)
		status
		;;
	*)
		echo "Usage: /etc/init.d/rpi-gpio-control {start|stop|status}"
		exit 1
		;;
esac
 
exit 0
EOF
sudo chmod +x /etc/init.d/rpi-gpio-control

## Autostart
mkdir -p ~/.config/autostart
cd ~/.config/autostart
tee iceweasel.desktop > /dev/null << EOF
[Desktop Entry]
Type=Application
Name=Iceweasel
Exec=iceweasel
StartupNotify=false
EOF
tee RGC.desktop > /dev/null << EOF
[Desktop Entry]
Type=Application
Name=RGC
Exec=sudo service rpi-gpio-control start
StartupNotify=false
EOF

################################################################
## reboot
################################################################
sudo reboot
