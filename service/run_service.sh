#!/bin/bash
# file: run_service.sh
# info: spawns a docker service image
# dependencies: assumes proxy variables are defined in the local environment

# image selection
IMAGE_REPO=${IMAGE_REPO:-s3p/service}
IMAGE_TAG=${IMAGE_TAG:-v0.3}
IMAGE_NAME="${IMAGE_REPO}:${IMAGE_TAG}"

# image configuration
ODL_NETWORK=${ODL_NETWORK:-False}
CAPABILITIES="--privileged --cap-add ALL --security-opt apparmor=docker-unconfined "
SERVICE_HOST=${SERVICE_HOST:-192.168.3.2}
STACK_PASS=${STACK_PASS:-stack}
# define _no_proxy based on the cluster topology
# connecting to ODL requires no_proxy to contain the EXACT IP address of the
# + service node, e.g. 192.168.3.2
_no_proxy=localhost,10.0.0.0/8,192.168.0.0/16,172.17.0.0/16,127.0.0.0/8,127.0.0.1,$SERVICE_HOST
SYSTEMD_ENABLING=" --tmpfs /run --tmpfs /run/lock --tmpfs /run/uuid --stop-signal=SIGRTMIN+3 "
CGROUP_MOUNT=" -v /sys/fs/cgroup:/sys/fs/cgroup:ro "
MOUNTS="-v /dev:/dev -v /lib/modules:/lib/modules $CGROUP_MOUNT $SYSTEMD_ENABLING "
PORT_MAP_OFFSET=50000
HORIZON_PORT_CONTAINER=80
DLUX_PORT_CONTAINER=8181
HORIZON_PORT_HOST=$(( $PORT_MAP_OFFSET + $HORIZON_PORT_CONTAINER ))
DLUX_PORT_HOST=$(( $PORT_MAP_OFFSET + $DLUX_PORT_CONTAINER ))
PORT_MAP="-p ${HORIZON_PORT_HOST}:${HORIZON_PORT_CONTAINER} -p ${DLUX_PORT_HOST}:${DLUX_PORT_CONTAINER}"
NETWORK_NAME="overlay-net"
NETWORK_SETTINGS="--net=$NETWORK_NAME $PORT_MAP"

NAME=${HOST_NAME:-service-node}
# TODO: the following section, up to the "run" seems unnecessary
CONF_FILE="$(pwd)/service.odl.local.conf"
if [ "$ODL_NETWORK" = "False" ] ; then
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
docker run -dit --name ${NAME} --hostname ${NAME} --env TZ=America/Los_Angeles \
    --env JAVA_HOME=/usr/lib/jvm/java-8-oracle --env JAVA_MAX_MEM=16g \
    --env http_proxy=$http_proxy --env https_proxy=$https_proxy \
    --env no_proxy=$_no_proxy \
    --env ODL_NETWORK=$ODL_NETWORK \
    --env STACK_PASS=$STACK_PASS \
    $NETWORK_SETTINGS \
    $MOUNTS \
    $CAPABILITIES \
    $IMAGE_NAME \
    /sbin/init

CONTAINER_SHORT_ID=$(docker ps -aqf "name=${NAME}")
# NOTE: if 'docker exec' is used immediately after the container launching,
# +the docker daemon will throw an error to the effect of "container not started"
# This is likely due to systemd initialization latency.
# waiting a few (?) seconds to launch bash or stack will allow 'docker exec' to succeed
# TODO: docker ps -f "ready" or some kind of  watch for container "readiness"
#echo "sleeping to allow systemd to wake up"
#sleep 5
#docker exec -it $CONTAINER_SHORT_ID su -c "/bin/bash" stack

