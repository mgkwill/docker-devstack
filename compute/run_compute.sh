#!/bin/bash
# file: ./run_compute.sh
# info: spawns a docker compute image
# dependencies: assumes proxy variables are defined in the local environment

HOST_ID=01
COMP_ID=07
NAME=compute-${HOST_ID}-${COMP_ID}
BASE_IMAGE=s3p/compute:working
ODL_NETWORK=false
COMMAND="/home/stack/start.sh"
CAPABILITIES="--privileged --cap-add ALL --security-opt apparmor=docker-unconfined "
MOUNTS="-v /dev:/dev -v /lib/modules:/lib/modules "

if [ -n "$1" ] ; then
    echo "Command argument supplied, running \"$1\" in $NAME..."
    COMMAND="$1"
fi

docker run -it --rm --name ${NAME} --hostname ${NAME} \
    --env http_proxy=$http_proxy --env https_proxy=$https_proxy \
    --env ODL_NETWORK=$ODL_NETWORK \
    --env STACK_PASS=stack \
    --env SERV_HOST=172.17.0.3 \
    $MOUNTS \
    $CAPABILITIES $BASE_IMAGE \
    $COMMAND

