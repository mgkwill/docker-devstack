FROM        matt-registry:4000/s3p/systemd:v0.1
MAINTAINER  OpenDaylight Integration Project Team <integration-dev@lists.opendaylight.org>

ENV     PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
        DEBIAN_FRONTEND=noninteractive \
        container=docker

# Install devstack dependencies
RUN     apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        iproute2 \
        iptables \
        lsb-release \
        net-tools \
        sudo \
        vim \
        python \
        bc bridge-utils bsdmainutils curl g++ gcc gettext git graphviz iputils-ping libffi-dev libjpeg-dev libmysqlclient-dev libpq-dev libssl-dev libxml2-dev libxslt1-dev libyaml-dev lsof openssh-server openssl pkg-config psmisc python2.7 python-dev python-gdbm screen tar tcpdump unzip uuid-runtime wget wget zlib1g-dev libkrb5-dev libldap2-dev libsasl2-dev memcached python-mysqldb sqlite3 fping conntrack curl dnsmasq-base dnsmasq-utils ebtables gawk genisoimage iptables iputils-arping kpartx libjs-jquery-tablesorter libmysqlclient-dev parted pm-utils python-mysqldb socat sqlite3 sudo vlan acl dnsmasq-base ebtables iptables iputils-arping iputils-ping libmysqlclient-dev postgresql-server-dev-all python-mysqldb sqlite3 sudo vlan libpcre3-dev dstat \
        python-virtualenv && \
        rm -rf /var/lib/apt/lists/*

# Add stack user
RUN     groupadd stack && \
        useradd -g stack -s /bin/bash -m stack && \
        echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# get devstack
RUN     git clone https://git.openstack.org/openstack-dev/devstack /home/stack/devstack && \
		chown -R stack:stack /home/stack/devstack

# copy local.conf & scripts
COPY    service.odl.local.conf /home/stack/service.odl.local.conf
COPY    service.ovs.local.conf /home/stack/service.ovs.local.conf
COPY    start.sh /home/stack/start.sh
COPY    restart.sh /home/stack/restart.sh
COPY    create_servers.sh /home/stack/create_servers.sh
RUN     chown -R stack:stack /home/stack && \
        chmod 766 /home/stack/start.sh && \
        chmod 766 /home/stack/restart.sh && \
        chmod 766 /home/stack/create_servers.sh

WORKDIR /home/stack
LABEL   version="0.5"
LABEL   nodetype="service"
# vim: set ft=dockerfile sw=4 ts=4 :

