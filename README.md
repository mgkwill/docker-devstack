# docker-devstack

Dockerfile and supporting files for fully functional dockerized Openstack nodes for S3P Testing (scale, stability, performance, security) of SDN controller used as network virtualization layer for OpenStack.
---
## Steps to set up an S3P cluster:
1. Select four systems (Make sure each system has enough RAM > 128 GB):  
  Host num - Services
  * 1 - control node
  * 2 - compute node
  * 3 - compute node
  * 4 - key-value server  

2. Install Fedora 23 server OS in each system.  Do disk partition manually.  
    Make sure the size of the root “/ “ is greater than 100 GiB.

3. Connect to each system with 10 Gib Network adapter.
   Configure networks (TODO: elaborate requirements)

4. Install and update docker to v1.10.3 in each system.  (TODO: Docker 1.12)
```bash
    $ dnf install docker
    $ dnf update docker
```

5. Install and start key-value server, a docker container consul on system four (4).
```bash
    $ docker pull progrium/consul
    $ docker run -d -p 8500:8500 -h consul --name consul progrium/consul -server –bootstrap
```

6. Start docker deamon process on system one (1), and pull out control node image.
```bash
    $ docker daemon -D -g /var/lib/docker -H unix:// -H tcp://0.0.0.0:2376 \
        --cluster-store=consul://<consul IP address>:8500 \
        --cluster-advertise=<NIC interface name to consul>:2376 \
        --storage-opt dm.basesize=60G  > /dev/null 2>&1 &

    $ docker pull rzang/service:v1

    $ docker images

    REPOSITORY                TAG       IMAGE ID         CREATED       SIZE
    docker.io/rzang/service   v1        7e2430884482     12 weeks ago  45.18 GB
```

7. Create control node container.
```bash
    $ docker run -dit -h ctlnode --name=control_node -e TZ=America/Los_Angeles \
        -e JAVA_HOME=/usr/lib/jvm/java-8-oracle -e JAVA_MAX_MEM=16g \
        --privileged --cap-add=ALL -v /dev:/dev -v /lib/modules:/lib/modules \
        --net=overlay-net 7e2430884482
```

8. Create overlay network.
```bash
    $ docker network create -d overlay --driver overlay --subnet 10.20.0.0/22 overlay-net
```

9. Start running Openstack on the control node.
```bash
    $ docker exec control_node su stack /home/stack/devstack/stack.sh
```

10. Start docker daemon process on system two and system three.
```bash
    $ docker daemon -D -g /var/lib/docker -H unix:// -H tcp://0.0.0.0:2376 \
        --cluster-store=consul://<consul IP address>:8500 \
        --cluster-advertise=<NIC interface name to consul>:2376 \
        --storage-opt dm.basesize=12G > /dev/null 2>&1 &
```

11. On system two and three, pull out compute images. Then create 200 compute
nodes on system two and 300 compute nodes on system three.
```bash
    $ docker pull rzang/compute-odl:v3

    $ docker pull rzang/compute:v3
```

