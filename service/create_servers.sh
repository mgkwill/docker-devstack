#!/bin/bash

USER=admin
PROJECT=demo
source /home/stack/devstack/openrc $USER $PROJECT
PROJECT_ID=$(openstack project list | grep " demo " | cut -d "|" -f 2 | tr -d " ")
net_id=$(openstack network show private -f shell --prefix net_ | grep "net_id" | grep -o '".*"' | sed 's/"//g')

# create servers
FLAVOR="m1.tiny"
IMAGE="cirros-0.3.4-x86_64-uec"

function create_server {
    if [ -z "$1" ] ; then
        echo "ERROR: A server ID nust be supplied"
    else
        ID="$1"
        export SERVER_NAME="test-${ID}"
        ZONE=""
        if [ -n "$2" ] ; then
            # specify zone if parent node is supplied
            PARENT_NODE="${2}"
            ZONE="--availability-zone nova:${PARENT_NODE}"
        fi
        if [ -z "$(openstack server list | grep "$SERVER_NAME" )" ] ; then
            echo "Creating server instance ${SERVER_NAME} on host ${PARENT_NODE} with flavor ${FLAVOR}"
            openstack server create --flavor $FLAVOR --image $IMAGE $ZONE --nic net-id=$net_id $SERVER_NAME
        else
            echo "ERROR: a server already exists with the name \"$SERVER_NAME\""
        fi
    fi
}

function create_security_group_rules {
    SEC_GRP_ID=$(openstack security group list | grep "$PROJECT_ID" | cut -d "|" -f 2 | tr -d ' ')
    # allow SSH
    openstack security group rule create --ingress $SEC_GRP_ID --protocol tcp --dst-port 22:22 --src-ip 0.0.0.0/0
    openstack security group rule create --egress $SEC_GRP_ID --protocol tcp --dst-port 22:22 --src-ip 0.0.0.0/0
    #allow ping
    openstack security group rule create --ingress --protocol ICMP $SEC_GRP_ID
    openstack security group rule create --egress --protocol ICMP $SEC_GRP_ID
}

function nsenter {
    # usage: nsenter [ IPNETNS ]
    if [ -z "$1" ] ; then
        NETNS=$(ip netns ls | grep dhcp )
	echo "No netns supplied as argument, using NETNS=$NETNS"
    else
        NETNS=$1
	echo "A netns was supplied as argument, using NETNS=$NETNS"
    fi
    sudo ip netns exec $NETNS /bin/bash
}

if [[ "$0" == *"bash"* ]] ; then 
    echo "Functions available in /home/stack/create_servers.sh:"
    grep function /home/stack/create_servers.sh | cut -d ' ' -f2 
else
    HOST_ID="n28"

    ID=1
    HOST_ZONE="compute-${HOST_ID}-001"
    create_server "$(printf "%.3d" $ID)"   # "$HOST_ZONE"
    openstack server show $SERVER_NAME

    ID=2
    HOST_ZONE="compute-${HOST_ID}-002"
    create_server "$(printf "%.3d" $ID)"   # "$HOST_ZONE"
    openstack server show $SERVER_NAME
    #ID=$(( $ID + 1 ))
    #create_server "$(printf "%.3d" $ID)" "compute-o17-002"
fi

# vim: set et sw=4 ts=4 :

