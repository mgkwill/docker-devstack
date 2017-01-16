#!/bin/bash
# file: run_service.sh
# info: spawns a docker service image 
# dependencies: assumes proxy variables are defined in the local environment

# image selection 
#BASE_IMAGE_ID=7e2430884482
#BASE_IMAGE="rzang/service:v1"
BASE_IMAGE="s3p/service:latest"

# image configuration 
NAME=service-node
ODL_NETWORK=true
CAPABILITIES="--privileged --cap-add ALL "
SERV_HOST=10.20.0.1
STACK_PASS=stack
# COMMAND="/home/stack/start.sh"

if [ -n "$1" ] ; then
    echo "Command argument supplied, running \"$1\" in $NAME..."
    COMMAND="$1"
fi

CONF_FILE="$(pwd)/control.ODL.local.conf"
if [ ! "$ODL_NETWORK" ] ; then 
    echo "Using no-ODL local.conf"
    CONF_FILE="$(pwd)/control.noODL.local.conf"
fi

CONF_FILE=$(pwd)/database_only.conf
echo "TEMPORARY, REMOVE THIS CONF FILE, ONLY FOR TESTING>>> $CONF_FILE"

docker run -it --name ${NAME} --hostname ${NAME} --env TZ=America/Los_Angeles \
    --env JAVA_HOME=/usr/lib/jvm/java-8-oracle --env JAVA_MAX_MEM=16g \
    --env http_proxy=$http_proxy --env https_proxy=$https_proxy \
    --env ODL_NETWORK=$ODL_NETWORK \
    --env STACK_PASS=$STACK_PASS \
    --env SERV_HOST=$SERV_HOST \
    -v /dev:/dev -v /lib/modules:/lib/modules \
    -v $CONF_FILE:/home/stack/devstack/local.conf \
    -v $(pwd)/start.sh:/home/stack/start.sh \
    -v $(pwd)/logs:/opt/stack/logs \
    $CAPABILITIES \
    $BASE_IMAGE \
    $COMMAND

