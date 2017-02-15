#!/bin/bash
# file: run_service.sh
# info: spawns a docker service image
# dependencies: assumes proxy variables are defined in the local environment

# image selection
IMAGE_REPO="s3p/service"
IMAGE_VERSION="v0.2"
IMAGE_NAME="${IMAGE_REPO}:${IMAGE_VERSION}"

# image configuration
ODL_NETWORK=true
CAPABILITIES="--privileged --cap-add ALL --cap-add NET_ADMIN --cap-add NET_RAW"
SERVICE_HOST=10.20.0.2
STACK_PASS=stack
# define _no_proxy based on the cluster topology
# connecting to ODL requires no_proxy to contain the EXACT IP address of the
# + service node, e.g. 10.20.0.2
_no_proxy=localhost,10.0.0.0/8,192.168.0.0/16,172.17.0.0/16,127.0.0.0/8,127.0.0.1,$SERVICE_HOST
CGROUP_MOUNT=""
MOUNTS="-v /dev:/dev -v /lib/modules:/lib/modules $CGROUP_MOUNT "
HORIZON_PORT_CONTAINER=80
HORIZON_PORT_HOST=61080
PORT_MAP="-p $HORIZON_PORT_HOST:$HORIZON_PORT_CONTAINER "
NETWORK_NAME="overlay-net"
NETWORK_SETTINGS="--net=$NETWORK_NAME $PORT_MAP"

NAME=service-node
CONF_FILE="$(pwd)/service.odl.local.conf"
if [ "$ODL_NETWORK" = "false" ] ; then
    CONF_FILE="$(pwd)/service.neutron.local.conf"
    echo "Using no-ODL (Neutron) local.conf ($CONF_FILE}"
else
    echo "Using OpenDaylight for local.conf ($CONF_FILE})"
fi
if [ -n "$1" ] ; then
    # if a command is specified as an argument to the script, use it,
    # else, default to the CMD defined in the Dockerfile
    echo "Command argument supplied, running \"$1\" in $NAME..."
    COMMAND="$1"
fi

echo "Starting up docker container from image ${IMAGE_NAME}"
echo "name: $NAME"
docker run -it --name ${NAME} --hostname ${NAME} --env TZ=America/Los_Angeles \
    --env JAVA_HOME=/usr/lib/jvm/java-8-oracle --env JAVA_MAX_MEM=16g \
    --env http_proxy=$http_proxy --env https_proxy=$https_proxy \
    --env no_proxy=$_no_proxy \
    --env ODL_NETWORK=$ODL_NETWORK \
    --env STACK_PASS=$STACK_PASS \
    $NETWORK_SETTINGS \
    $MOUNTS \
    $CAPABILITIES \
    $IMAGE_NAME \
    /bin/bash

CONTAINER_SHORT_ID=$(docker ps -aqf "name=${NAME}")
#docker exec -it $CONTAINER_SHORT_ID /home/stack/start.sh

