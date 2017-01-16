FROM 		ubuntu:14.04
MAINTAINER	OpenDaylight Int/Test Project Team <integration-dev@lists.opendaylight.org>

ENV		PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Add stack user
RUN		groupadd stack && \
		useradd -g stack -s /bin/bash -m stack && \
		echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install git and sshd
RUN 		apt-get update && \
		apt-get install -y --no-install-recommends git \
		openssh-server ca-certificates openvswitch-common \
		openvswitch-switch dbus \
		python-pip \
		iptables \
		bc bridge-utils bsdmainutils curl g++ gcc gettext git graphviz \
		iputils-ping libffi-dev libjpeg-dev libmysqlclient-dev libpq-dev libssl-dev \
		libxml2-dev libxslt1-dev libyaml-dev lsof openssh-server openssl pkg-config \
		psmisc python2.7 python-dev python-gdbm screen tar tcpdump unzip uuid-runtime \
		wget zlib1g-dev libkrb5-dev libldap2-dev libsasl2-dev memcached \
		python-mysqldb sqlite3 libpcre3-dev \
		python-virtualenv \
		apache2 \
		libapache2-mod-wsgi \
		rabbitmq-server mysql-server && \
		rm -rf /var/lib/apt/lists/*

# Install vim for utility, remove before final build
RUN 		apt-get update && apt-get install -y --no-install-recommends vim  && rm -rf /var/lib/apt/lists/*

# Get devstack
USER		stack
# TODO: lock down particular release of OpenStack here
RUN		git clone https://git.openstack.org/openstack-dev/devstack \
		/home/stack/devstack
# Copy and chown local.conf to stack
COPY 		control.ODL.local.conf /home/stack/devstack/local.conf
RUN 		sudo chown stack:stack /home/stack/devstack/local.conf

# Copy start.sh and chown to stack
COPY		start.sh /home/stack/
RUN		sudo chown stack:stack /home/stack/start.sh && chmod 766 /home/stack/start.sh

CMD		["/home/stack/start.sh"]

# vim: set ft=dockerfile sw=4 ts=4 :
