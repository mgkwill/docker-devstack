#!/bin/bash
# file: ./create_host_bridge.sh
# info: creates a Linux bridge and binds a physical adapter to it

function fn_create_host_bridge {
    # echo ${0}::${FUNCNAME[0]}
    # info: creates a linux bridge and binds a physical adapter to it
    local BR_NAME=${1}
    if [ -z "$(find /sys/class/net -name $BR_NAME)" ] ; then
        local ADAPTER=${2}
        local IPADDR=$(ip -o -4 addr show dev $ADAPTER | awk '{print $4}')

        echo "NOTE:: creating host bridge \"$BR_NAME\" with adapter \"$ADAPTER\""
        ip addr flush $ADAPTER
        ip link set $ADAPTER up
        ip link set $ADAPTER promisc on
        brctl addbr $BR_NAME
        brctl addif $BR_NAME $ADAPTER
        ip addr add $IPADDR dev $BR_NAME
        #brctl showmacs $BR_NAME
        ip link set $BR_NAME up
        echo "NOTE:: to remove  host bridge \"$BR_NAME\" with adapter \"$ADAPTER\", use:"
        echo -e "\t./create_host_bridge.sh remove"
    else
        echo -e "\nERROR: Bridge \"$BR_NAME\" already exists, no changes were made."
        echo "Bridge status ($BR_NAME): "
        brctl show $BR_NAME
    fi
}

function fn_remove_host_bridge {
    # info: removes the bridge and re-establishes the physical adapter
    # echo ${0}::${FUNCNAME[0]}
    local BR_NAME=${1}
    if [ -n "$(find /sys/class/net -name $BR_NAME)" ] ; then
        echo "NOTE: removing host bridge \"$BR_NAME\""
        local ADAPTER=${2}
        local IPADDR=$(ip -o -4 addr show dev $BR_NAME | awk '{print $4}')

        ip addr flush $BR_NAME
        ip link set $BR_NAME down
        brctl delif $BR_NAME $ADAPTER
        brctl delbr $BR_NAME
        ip addr add $IPADDR dev $ADAPTER
        ip link set $ADAPTER up
        ip link set $ADAPTER promisc off
    else
        echo -e "WARNING: Bridge \"$BR_NAME\" does not exist. No changes were made."
    fi
}


# NOTE: this assumes that the physical interface has a valid IP on this subnet
# Enter these variables to change the bridge properties
# change this: 
HOST_IFACE=${1}
case "$HOST_IFACE" in 
    "eno2")
        PHYSICAL_SUBNET=10.11.20.0/22
        PHYS_DHCP_RANGE=10.11.20.1/25
        HOST_BRIDGE_NAME=br_data
        ;;
    "eno3")
        PHYSICAL_SUBNET=10.11.124.0/22
        PHYS_DHCP_RANGE=10.11.127.1/25
        HOST_BRIDGE_NAME=br_tenant
        ;;
    "eno4")
        PHYSICAL_SUBNET=10.11.24.0/22
        PHYS_DHCP_RANGE=10.11.27.1/25
        HOST_BRIDGE_NAME=br_mgmt
        ;;
    *)
        echo "ERROR: no interface named $HOST_IFACE exists, exiting."
        exit
esac

# derived variables
HOST_SUBNET_IFACE=$(ip -o -4  a s to $PHYSICAL_SUBNET | awk '{print $2}')
HOST_IFACE_ADDR=$(ip -o -4 a s to $PHYSICAL_SUBNET | awk '{print $4}')
DOCKER_NETWORK_NAME=docknet_${HOST_BRIDGE_NAME}

if [ -z "${2}" ] ; then
    fn_create_host_bridge $HOST_BRIDGE_NAME $HOST_SUBNET_IFACE
else
    # ask user if they want to remove the bridges and docker network
    if [ "$2" == "remove" ] ; then
        fn_remove_host_bridge $HOST_BRIDGE_NAME $HOST_IFACE
    fi
fi

# vim: set ft=sh et sw=4 ts=4 :

