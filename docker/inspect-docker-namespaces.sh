#!/bin/bash
# assumes that a container exists with "super" privileges
# see https://github.com/moby/moby/issues/14666
#   https://github.com/moby/moby/issues/14743#issuecomment-124264534

function fn_target_exists {
    echo -e "\nWARNING: Analysis netns target already exists:\n\t$(ls -al $LINK_TARGET)\n"
}

function fn_demonstrate_netns_functionality {
    echo "INFO: The following is the output of \"ip netns exec $INSPECTION_NETNS_NAME ip a\" :: "
    ip netns exec $INSPECTION_NETNS_NAME ip a
}

function fn_create_link {
    if [ ! -L "${LINK_TARGET}" ] ; then
        ln -s ${LINK_SOURCE} ${LINK_TARGET} && \
            echo "INFO:: Link created: ${LINK_TARGET} -> ${LINK_SOURCE}"
    else
        fn_target_exists
    fi
    echo "INFO: Remove the link with: \"unlink ${LINK_TARGET}\""
}

function fn_link_container_netns {
    # link the docker container netns to an analysis netns accessible from the root netns
    HOST_PROC_ROOT="/proc"
    INSPECTION_NETNS_NAME="netns-$SUPER_CONTAINER_NAME"
    mkdir -p $HOST_NETNS_ROOT
    LINK_SOURCE=${HOST_PROC_ROOT}/$CPID/ns/net
    LINK_TARGET="${HOST_NETNS_ROOT}/${INSPECTION_NETNS_NAME}"

    fn_create_link
    # NOTE: the LINK_TARGET now points to the container's netns so you can inspect the container netns with: 
    fn_demonstrate_netns_functionality
}

function fn_link_docker_netns {
    # link the 'docker network'-netns to the target netns
    INSPECTION_NETNS_NAME="netns-$DOCKER_NETWORK_NAME"
    mkdir -p $HOST_NETNS_ROOT
    # link the docker network netns to an analysis netns accessible from the root netns
    LINK_SOURCE="${DOCKER_NETNS_ROOT}/$DOCKER_NETWORK_NS_ID"
    LINK_TARGET="${HOST_NETNS_ROOT}/${INSPECTION_NETNS_NAME}"

    fn_create_link
    # note: the link now points to the private docker netns for "$DOCKER_NETWORK_NAME"
    fn_demonstrate_netns_functionality
}

SUPER_CONTAINER_NAME=${1:-"service-node"}
HOST_NETNS_ROOT="/var/run/netns"

CPID=$(docker inspect -f '{{.State.Pid}}' $SUPER_CONTAINER_NAME)
if [ -n "$CPID" ] ; then 
    fn_link_container_netns
else
    echo "${0}: ERROR: failed to obtain container PID of $SUPER_CONTAINER_NAME"
fi
echo

DOCKER_NETWORK_NAME=overlay-net
# it's not obvious from inspection of the netns listed in /var/run/docker/netns and the network names
# TODO: figure out how to get this ID.
DOCKER_NETWORK_NS_ID="${2:-'2-06d6f5726d'}"
DOCKER_NETNS_ROOT="/var/run/docker/netns"
SOURCE_NETNS="${DOCKER_NETNS_ROOT}/${DOCKER_NETWORK_NS_ID}"
if [ -f "$SOURCE_NETNS" ] ; then 
    fn_link_docker_netns
else
    echo "${0}: ERROR: docker network namespace \"$DOCKER_NETWORK_NS_ID\" does not exist in $DOCKER_NETNS_ROOT"
fi
echo

