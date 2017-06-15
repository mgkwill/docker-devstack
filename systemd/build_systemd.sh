#!/bin/bash
# file: build_systemd.sh
# info: builds a docker image with systemd
IMAGE_REPO=${IMAGE_REPO:-s3p/systemd}
IMAGE_TAG=${IMAGE_TAG:-latest}

if [ -n "$1" ] ; then
    # use arg as image tag if supplied
    IMAGE_TAG="$1"
fi
IMAGE_NAME=${IMAGE_REPO}:${IMAGE_TAG}
DOCKERFILE=${DOCKERFILE:-systemd.ubuntu1604.Dockerfile}

echo "Building $IMAGE_NAME from Dockerfile=$DOCKERFILE at $(date) ... "
docker build -t ${IMAGE_NAME} -f ${DOCKERFILE} \
    --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy .

if [ $? = 0 ] ; then
    docker images $IMAGE_NAME
    echo "Docker image $IMAGE_NAME built successfully."
    echo "To quickly test it, you can launch it with:"
    echo "docker run -it --rm --env http_proxy=$http_proxy --env https_proxy=$https_proxy --env no_proxy=$no_proxy $IMAGE_NAME bash"
else
    echo "An error occurred during the build of $IMAGE_NAME"
fi

