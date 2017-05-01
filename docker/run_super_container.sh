#!/bin/bash


CAPABILITIES="--privileged --cap-add ALL --security-opt apparmor=docker-unconfined "
CGROUP_MOUNT=" -v /sys/fs/cgroup:/sys/fs/cgroup"
MOUNTS="-v /dev:/dev -v /lib/modules:/lib/modules $CGROUP_MOUNT "
_no_proxy=localhost,10.0.0.0/8,192.168.0.0/16,172.17.0.0/16,127.0.0.0/8

DOCKER_NETWORK="overlay-net"
DOCKER_NET_OPTS="--net $DOCKER_NETWORK "
IMAGE_NAME=""
NAME=super_privileged
if [ -n "$1" ]; then
    IMAGE_NAME="$1"
    docker run -it --rm \
        --env http_proxy=$http_proxy --env https_proxy=$https_proxy \
        --env no_proxy=$_no_proxy \
        --env container=docker \
        $MOUNTS \
        $CAPABILITIES \
        $DOCKER_NET_OPTS \
        $IMAGE_NAME \
        /bin/bash

else
    echo "Error: no image specified. Specify a valid docker image ID as an argument."
    docker images 
fi

