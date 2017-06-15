#!/bin/bash
PHYS_HOST_PUB_IP="10.166.33.49"
NOVNC_PROXY_PORT="$(grep novncproxy_port /home/stack/devstack/local.conf | cut -d "=" -f 2 | tr -d " ")"
MAPPED_PORT=$(( $NOVNC_PROXY_PORT + 50000 ))
source /home/stack/devstack/openrc admin demo
if [ -z "$1" ] ; then 
	echo -e "\nNo instance ID specified, try again with the form ./get_public_console_url.sh <instance ID>"
	echo -e "\nAvailable OpenStack servers: "
	openstack server list
	echo
else
	INSTANCE_ID="$1"
	openstack console url show $INSTANCE_ID | sed "s/${SERVICE_HOST}/${PHYS_HOST_PUB_IP}/g" | sed "s|:${NOVNC_PROXY_PORT}/|:${MAPPED_PORT}/|g"
	echo -e "\nAdd the following to the URL to modify the browser title: \"&title=${INSTANCE_ID}\" \n"
fi
