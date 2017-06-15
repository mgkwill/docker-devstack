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
    REMOVE_COMMAND="unlink ${LINK_TARGET}"
    echo "INFO: Remove the link with: \"${REMOVE_COMMAND}\" or run \"${REMOVE_LINKS_SCRIPT}\""
    echo $REMOVE_COMMAND >> ${REMOVE_LINKS_SCRIPT}
    chmod u+x ${REMOVE_LINKS_SCRIPT}
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

function fn_usage {
    echo "Usage of inspect-docker-namespaces.sh::"
    echo "  ./inspect-docker-namespaces.sh <container_name> <docker network namespace>"
    echo "      where <docker netns> is one of \"$(ls /var/run/docker/netns/)\""
}

HOST_NETNS_ROOT="/var/run/netns"
REMOVE_LINKS_SCRIPT="./remove_netns_links.sh"

if [ -z "$1" -o -z "${2}" ] ; then 
    fn_usage
else
    # remove "here document" created earlier
    rm -rf ${REMOVE_LINKS_SCRIPT}
    SUPER_CONTAINER_NAME=${1}

    # get the container's PID
    CPID=$(docker inspect -f '{{.State.Pid}}' $SUPER_CONTAINER_NAME)
    if [ -n "$CPID" ] ; then 
        fn_link_container_netns
    else
        echo "${0}: ERROR: failed to obtain container PID of $SUPER_CONTAINER_NAME.  It doesn't appear to be running on this host:"
        docker ps -a
    fi
    echo

    ## create links for docker network namespaces into root netne
    DOCKER_NETWORK_NAME=overlay-net
    # TODO: figure out how to get this ID.
    # Each container linked into this netns will have a field in their config: .NetworkSettings.SandboxKey
    # e.g.: "SandboxKey": "/var/run/docker/netns/1be2fafe4eed",
    SANDBOX_KEY=$(docker inspect -f '{{.NetworkSettings.SandboxKey}}' $SUPER_CONTAINER_NAME)
    DOCKER_NETNS=${SANDBOX_KEY##*/} # trim leading path 
    DOCKER_NETWORK_NS_ID="${2}"
    DOCKER_NETNS_ROOT="/var/run/docker/netns"
    SOURCE_NETNS="${DOCKER_NETNS_ROOT}/${DOCKER_NETWORK_NS_ID}"
    if [ -f "$SOURCE_NETNS" ] ; then 
        fn_link_docker_netns
    else
        echo "${0}: ERROR: docker network namespace \"$DOCKER_NETWORK_NS_ID\" does not exist in $DOCKER_NETNS_ROOT"
        ls -al ${DOCKER_NETNS_ROOT}
    fi
    echo

fi
