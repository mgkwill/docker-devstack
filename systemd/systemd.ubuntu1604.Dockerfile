FROM        ubuntu:16.04
MAINTAINER  OpenDaylight Integration Project Team <integration-dev@lists.opendaylight.org>

ENV     PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
        DEBIAN_FRONTEND=noninteractive \
        container=docker

# https://github.com/solita/docker-systemd
# Don't start any optional services except for the few we need.
RUN find /etc/systemd/system \
		/lib/systemd/system \
		-path '*.wants/*' \
		-not -name '*journald*' \
		-not -name '*systemd-tmpfiles*' \
		-not -name '*systemd-user-sessions*' \
		-exec rm \{} \;

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in $(ls *); do [ "$i" = systemd-tmpfiles-setup.service ] || rm -f $i; done); \
	rm -f /lib/systemd/system/multi-user.target.wants/*;\
	rm -f /etc/systemd/system/*.wants/*;\
	rm -f /lib/systemd/system/local-fs.target.wants/*; \
	rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
	rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
	rm -f /lib/systemd/system/basic.target.wants/*

RUN systemctl set-default multi-user.target
VOLUME [ "/sys/fs/cgroup" ]

CMD     ["/sbin/init"]

# vim: set ft=dockerfile sw=4 ts=4 :
