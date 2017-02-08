#!/bin/bash
# file: start_overlay_net.sh
NET_DRIVER=overlay
SUBNET=10.20.0.0/22
NET_NAME=overlay-net

NET_JSON=$(docker network inspect $NET_NAME &2>/dev/null )

if [ -z "$(echo $NET_JSON | grep $NET_NAME)" ] ; then 
    # create network if not present
    echo "Docker network \"$NET_NAME\" does not exist."
    echo "Creating docker network with:"
    echo "Subnet: $SUBNET"
    echo "Driver: $NET_DRIVER"
    echo "Name: $NET_NAME"
    NET_ID=$(docker network create --driver $NET_DRIVER --subnet $SUBNET $NET_NAME)
    echo "Network creation successful!"
    echo "Network ID: $NET_ID"
else
    echo "WARNING:: Docker network \"$NET_NAME\" already exists: "
    echo "  Examine the network properties below to verify it is correctly configured"
    docker network inspect $NET_NAME
fi

