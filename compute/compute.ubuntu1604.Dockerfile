FROM        s3p/systemd:v0.1
MAINTAINER  OpenDaylight Integration Project Team <integration-dev@lists.opendaylight.org>

ENV     PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
        DEBIAN_FRONTEND=noninteractive \
        container=docker

# Install devstack dependencies
RUN     apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        inetutils-ping \
        iproute2 \
        iptables \
        lsb-release \
        openssh-server \
        openvswitch-common \
        openvswitch-switch \
        sudo \
        vim && \
        rm -rf /var/lib/apt/lists/*

# Add stack user
RUN     groupadd stack && \
        useradd -g stack -s /bin/bash -m stack && \
        echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# copy local.conf & scripts
COPY    compute.ubuntu1604.local.conf /home/stack/local.conf
COPY    start.sh /home/stack/start.sh
COPY    restart.sh /home/stack/restart.sh
RUN     chown -R stack:stack /home/stack && \
        chmod 766 /home/stack/start.sh && \
        chmod 766 /home/stack/restart.sh

# get devstack
RUN     git clone https://git.openstack.org/openstack-dev/devstack /home/stack/devstack && \
		chown -R stack:stack /home/stack/devstack

# vim: set ft=dockerfile sw=4 ts=4 :

