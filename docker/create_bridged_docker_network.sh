#!/bin/bash
# file: create_bridged_docker_network.sh
# info: creates a docker network based on a bridge

function fn_create_docker_network {
    # echo ${0}::${FUNCNAME[0]}
    local NET_NAME=${1}
    if [ -z "$(docker network inspect -f '{{.Name}}' $NET_NAME 2>/dev/null)" ] ; then
        local SUBNET=${2}
        local DHCP_RANGE=${3}
        echo "NOTE:: creating docker network \"$NET_NAME\" with subnet $SUBNET and DHCP range $DHCP_RANGE ..."
        docker network create \
            --internal=false --driver=bridge --label "nettype=mgmt" --label "domain=s3p" \
            --subnet=${SUBNET} --ip-range=$DHCP_RANGE \
            ${NET_NAME}
        echo -e "NOTE:: to remove the new docker network, use\n\tcreate_bridged_docker_network.sh remove"
    else
        echo -e "\nERROR: a docker network named \"$NET_NAME\" already exists.  No changes were made."
        echo -e "\tYou can show network details with: docker network inspect $NET_NAME\n"
    fi
}

function fn_remove_docker_network {
    # echo ${0}::${FUNCNAME[0]}
    local NET_NAME=${1}
    if [ -n "$(docker network inspect -f '{{.Name}}' $NET_NAME 2>/dev/null)" ] ; then
        docker network rm $NET_NAME
    else
        echo "WARNING: docker network \"$NET_NAME\" does not exist. No docker networks removed."
    fi
}

# NOTE: this assumes that the physical interface has a valid IP on this subnet
PHYSICAL_SUBNET=10.11.24.0/22
PHYS_DHCP_RANGE=10.11.27.2/25
HOST_BRIDGE_NAME=br_mgmt
DOCKER_NETWORK_NAME=docknet_${HOST_BRIDGE_NAME}

if [ -z "${1}" ] ; then
    fn_create_docker_network $DOCKER_NETWORK_NAME $PHYSICAL_SUBNET $PHYS_DHCP_RANGE
else
    # ask user if they want to remove the docker network
    if [ "$1" == "remove" ] ; then
        fn_remove_docker_network $DOCKER_NETWORK_NAME
    fi
fi

# vim: set ft=sh et sw=4 ts=4 :

