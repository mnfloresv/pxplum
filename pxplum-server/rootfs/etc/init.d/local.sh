#!/bin/sh
# /etc/init.d/local.sh - Local startup commands.
#
# All commands here will be executed at boot time.
#
. /etc/init.d/rc.functions

echo "Starting local startup commands... "

# Set static IP
ifconfig eth0 10.0.0.1

# Start web server
rackup /home/pxplum/pxplum-web/config.ru -p 80 -D

