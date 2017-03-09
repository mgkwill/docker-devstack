* create a text file that exports all of the variables that to override like:

```shell
cat > myvars <<EOF
    export IMAGE_REPO=s3p/service
    export IMAGE_TAG=${IMAGE_VERSION:-v0.3}
    export ODL_NETWORK=True
    export SERVICE_HOST="192.168.3.2"
    export HOST_NAME=control-node
    export DOCKERFILE="service.ubuntu1604.Dockerfile"
EOF
```

* build the image by first source-ing the variables then building the image
 source myvars ; ./build_service.sh

* run the image
 source myvars ; ./run_service.sh

* you should now be at a bash prompt in the service node
root@service-node $

