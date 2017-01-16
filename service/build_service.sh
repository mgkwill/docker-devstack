#!/bin/bash
# file: build_service.sh
# info: builds a docker service image 
IMAGE_NAME=s3p/service:latest

docker build -t ${IMAGE_NAME} \
    --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy .
