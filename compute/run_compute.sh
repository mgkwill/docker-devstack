#!/bin/bash
# file: ./run_compute.sh
# info: spawns a docker compute image 
# dependencies: assumes proxy variables are defined in the local environment

HOST_ID=01
COMP_ID=01
BASE_IMAGE=s3p/compute:latest
COMMAND="/home/stack/start.sh"

if [ -z "$1" ] ; then
    COMMAND="$1"
fi

NAME=compute.${HOST_ID}.${COMP_ID}

docker run -it --name ${NAME} --hostname ${NAME} \
    --env http_proxy=$http_proxy --env https_proxy=$https_proxy \
    $BASE_IMAGE \
    $COMMAND

