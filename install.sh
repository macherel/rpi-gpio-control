#!/bin/bash

RGC_HOME=~/rpi-gpio-control

################################################################
## Iceweasel + VLC plugin
################################################################
sudo apt-get update
sudo apt-get install iceweasel browser-plugin-vlc

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
export DISPLAY=":0.0"
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
# Default-Start:     3 4 5
# Default-Stop:      0 1 2 6
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
		nohup \$RUN 2>&1 > \$RGC_HOME/rpi-gpio-control.log &
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
sudo update-rc.d rpi-gpio-control defaults

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
