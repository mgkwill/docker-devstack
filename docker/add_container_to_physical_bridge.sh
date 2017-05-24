#!/bin/bash
# this will
# 1) create a pair of veth interfaces
# 2) add one to a physical bridge (assumed to exist)
# 3) add the peer to a docker container netns
# 4) set its IP address
function fn_get_host_index {
    # NOTE: this will need modification for cperf or other clusters
    local PHYS_HOST_NAME=$(hostname)
    local __hix=${PHYS_HOST_NAME##"an11-"} # trim rack ID from hostname (e.g. an11-31-odl -> 31-odl-perf)
    local H_IXd=${__hix%%-*} # trim trailing characters after rack position (e.g. 31-odl-perf -> 31)
    echo "$H_IXd"
}

function fn_link_container_netns {
    mkdir -p $HOST_NETNS_ROOT
    # derived variables
    SANDBOX_KEY=$(docker inspect -f '{{.NetworkSettings.SandboxKey}}' $CONTAINER_NAME)
    NETNS_NAME="netns-$CONTAINER_NAME"
    ln -s $SANDBOX_KEY $HOST_NETNS_ROOT/$NETNS_NAME
}

function fn_attach_veth_to_container {
    ## Attach veth to container
    CONTAINER_VETH_NAME="ethphys${A_IX}"
    ip link set $VETH_CONT netns $NETNS_NAME
    ip netns exec $NETNS_NAME ip link set dev $VETH_CONT name $CONTAINER_VETH_NAME
    # set the device mac address
    ip netns exec $NETNS_NAME ip link set dev $CONTAINER_VETH_NAME address $CONTAINER_MAC
    # set the adapter IP address
    ip netns exec $NETNS_NAME ip address add $CONTAINER_IP dev $CONTAINER_VETH_NAME
    echo "Container net-namespace:"
    ip netns exec $NETNS_NAME ip link set dev $CONTAINER_VETH_NAME up
    ip netns exec $NETNS_NAME ip a s
    echo
}

function fn_create_and_link_veth {
    ## Create veth pair (peers)
    VETH_BASE="ve${H_IXx}${C_IXx}${A_IX}"
    VETH_HOST=${VETH_BASE}h
    VETH_CONT=${VETH_BASE}c
    ip link add $VETH_HOST type veth peer name $VETH_CONT
    ip link set dev $VETH_HOST up
    ## attach veth in host netns to PHYS_BRIDGE
    brctl addif $PHYS_BRIDGE_NAME $VETH_HOST

    fn_attach_veth_to_container
}

function fn_usage {
    echo "Usage:"
    echo "add_container_to_physical_bridge.sh <bridge name> <container ID> <adapter_index>"
    echo
}

# main:
# lab constants
MAC_PREFIX="fe:53:00"
HOST_NETNS_ROOT=/var/run/netns

# note: the bridge name should be passed as an input argument
if [ -z "${1}" ] ; then
    echo "ERROR: no bridge name supplied."
    fn_usage
    exit
else
    PHYS_BRIDGE_NAME=${1}
    if [ ! -h "/sys/class/net/${PHYS_BRIDGE_NAME}" ] ; then
        echo "ERROR: bridge \"$PHYS_BRIDGE_NAME\" does not exist.  Aborting."
        exit 1
    fi
fi

if [ -z "${2}" ] ; then
    echo "ERROR: no container ID supplied."
    fn_usage
    exit
else
    CONTAINER_NAME=${2}
    CPID=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME)
    if [ $? -eq 1 ] ; then
        echo "ERROR: container \"$CONTAINER_NAME\" does not exist on this host.  Aborting."
        exit 1
    fi
fi

if [ -z "${3}" ] ; then
    echo "ERROR: no adapter index supplied."
    fn_usage
    exit
else
    ADAPTER_IX=${3}
fi

fn_link_container_netns

# determine subnet from bridge
# TODO: these are assumptions based on local lab topology
SUBNET_BASE="10.11"
SUBNET_SEGMENT="27"
if [ "$PHYS_BRIDGE_NAME" == "br_data" ] ; then
    SUBNET_SEGMENT="20"
fi
SUBNET_PREFIX="${SUBNET_BASE}.${SUBNET_SEGMENT}"
# echo $SUBNET_PREFIX
NETMASK_LEN=22

# NOTE: this is a hard part, keeping track of which address has been assigned
# + this can be deterministic where each container gets an index which is used
# + to create the IP address, MAC address, VETH numbering, etc
H_IXd=$(fn_get_host_index)
# H_IXd=31
# host index (rack position), convert to 2 hex digits
# H_IXx (hex representation of host id) can be passed as an input argument or used from the environment
H_IXx=${H_IXx:-$(printf "%.2x" $H_IXd)}

C_IXd=$(cat container_counter.txt)

# container index (container id per host), convert to 2 hex digits
# TODO: need a place to keep track of the available indices (although they should increase monotonically from 2 to 256
CONTAINER_IP="${SUBNET_PREFIX}.${C_IXd}/${NETMASK_LEN}"

C_IXx=$(printf "%.2x" $C_IXd)
A_IX="$(printf "%.2x" $ADAPTER_IX)"
# increment ADAPTER_IX for subsequent interfaces added to this container
CONTAINER_MAC="${MAC_PREFIX}:${H_IXx}:${C_IXx}:${A_IX}"

fn_create_and_link_veth

# if all goes well, we've linked the container to the bridge, update the counter
if [ $? -eq 0 ] ; then
    # display status info
    echo "Successfully linked container $CONTAINER_NAME to bridge $PHYS_BRIDGE_NAME"
    echo -e "H_IX:  \t${H_IXd} (0x${H_IXx})"
    echo -e "C_IX:  \t${C_IXd} (0x${C_IXx})"
    echo -e "C_MAC: \t${CONTAINER_MAC}"
    echo -e "C_IP4: \t${CONTAINER_IP}"
    echo -e "C_veth:\t${CONTAINER_VETH_NAME} (${VETH_CONT})"
    echo -e "H_veth:\t${VETH_HOST}"
    echo
    # increment the container count
    C_IX_NEXT=$(( ${C_IXd} + 1 ))
    echo $C_IX_NEXT > container_counter.txt
fi

unlink $HOST_NETNS_ROOT/$NETNS_NAME

echo "You can remove the links created just now by simply removing the veth peer from the root netns with:"
echo "    ip link delete $VETH_HOST"

