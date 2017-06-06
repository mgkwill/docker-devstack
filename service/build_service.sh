#!/bin/bash
# file: build_service.sh
# info: builds a docker service image

function tag_and_push_latest {
    IMAGE_TAG=latest
    IMAGE_NAME_LATEST=${IMAGE_REPO}:${IMAGE_TAG}
    docker tag $IMAGE_NAME $IMAGE_NAME_LATEST
    docker push $IMAGE_NAME
    docker push $IMAGE_NAME_LATEST
}

IMAGE_REPO=${IMAGE_REPO:-s3p/service}
IMAGE_TAG=${IMAGE_TAG:-latest}

if [ -n "$1" ] ; then
    # use arg as image tag if supplied
    IMAGE_TAG="$1"
fi
IMAGE_NAME=${IMAGE_REPO}:${IMAGE_TAG}
DOCKERFILE=${DOCKERFILE:-"service.allpackages.Dockerfile"}

echo "Building $IMAGE_NAME from Dockerfile=$DOCKERFILE at $(date) ... "
docker build -t ${IMAGE_NAME} -f ${DOCKERFILE} \
    --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy .

if [ $? = 0 ] ; then
    docker images $IMAGE_NAME
    echo "Docker image $IMAGE_NAME built successfully."
    echo "To quickly test it, you can launch it with:"
    echo "docker run -it --rm --env http_proxy=$http_proxy --env https_proxy=$https_proxy --env no_proxy=$no_proxy $IMAGE_NAME bash"

    tag_and_push_latest
else
    echo "An error occurred during the build of $IMAGE_NAME"
fi

