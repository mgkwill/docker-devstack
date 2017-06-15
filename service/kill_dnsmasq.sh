#!/bin/bash
DHCP_LOG="/opt/stack/logs/q-dhcp.log"

DHCP_PID="$(pgrep dnsmasq)"

while [ -z "$(grep "Rootwrap error running command: \['kill', '-9', '${DHCP_PID}'\]" $DHCP_LOG )" ] ; do 
	echo "Waiting to kill dnsmasq:${DHCP_PID} if it throws errors..."
	sleep 1
done

sudo kill -9 $DHCP_PID

