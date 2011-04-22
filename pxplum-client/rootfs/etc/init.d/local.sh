#!/bin/sh
# /etc/init.d/local.sh - Local startup commands.
#
# All commands here will be executed at boot time.
#
. /etc/init.d/rc.functions

echo "Starting local startup commands... "

# Register Pxplum service
HWADDR=$( ifconfig eth0 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | sed 's/:/-/g' )
IP=$( ifconfig eth0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}' )
#slptool register service:pxplum://slitaz-pxplum-client "(hwaddr=$HWADDR),(ip=$IP),(os=slitaz-pxplum-client)"
cat <<EOF >> /etc/slp.reg

#Register Pxplum service
service:pxplum://$IP,en,65535 
hwaddr=$HWADDR
ip=$IP
os=slitaz-pxplum-client
EOF
