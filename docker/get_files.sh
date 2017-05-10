#!/bin/bash
CONTAINER_ID=$1
if [ -n "$(docker ps -a | grep ${CONTAINER_ID})" ] ; then 
    TARBALL=/home/stack/${CONTAINER_ID}.archive.tar.gz
    docker exec -it $CONTAINER_ID tar --exclude /home/stack/docker-devstack --exclude /home/stack/devstack -cf ${TARBALL} /home/stack
    docker cp ${CONTAINER_ID}:${TARBALL} .
else
    echo "ERROR: \"${CONTAINER_ID}\" is not a valid container..."
fi
