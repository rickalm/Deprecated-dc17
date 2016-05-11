##################################
###
### This project starts from centos:7 build and installs systemd (container) and latest docker
###
### - remount /sys/fs/cgroups within the context its launched into (side effect of --priv)
### - launches docker (Working how to let SystemD do this
### - passes control to SystemD (unless told to do otherwise)
###
### Ideas (and portions of code in the project) originated from
###  https://github.com/jpetazzo/dind
###  https://github.com/maci0/docker-systemd-unpriv
###
##################################

FROM centos:centos7
MAINTAINER Rick Alm "rickalm@aol.com"
ENV container docker

VOLUME ["/run"]
VOLUME ["/sys/fs/cgroup"]
VOLUME ["/var/lib/docker"]

RUN \
  yum -y update \
    || exit 1; \
  yum -y swap -- remove systemd-container systemd-container-libs -- install systemd systemd-libs dbus \
    || exit 1; \
  yum -y install \
    lxc \
    less \
    iptables \
    || exit 1; \
  \
  systemctl mask \
    dev-mqueue.mount \
    dev-hugepages.mount \
    sys-kernel-config.mount \
    sys-kernel-debug.mount \
    sys-fs-fuse-connections.mount \
    systemd-remount-fs.service \
    display-manager.service \
    systemd-logind.service \
    console-getty.service \
    getty@tty1.service \
    graphical.target \
    || exit 1; \
  \
  systemctl mask \
    tmp.mount \
    || exit 1; \
  \
  curl -sSL https://get.docker.com/ | sh; \
  \
  yum -y clean all \
    || exit 1; \
  \
  /bin/true

ENTRYPOINT  ["/start_dind.sh"]
CMD  ["/usr/lib/systemd/systemd"]

# Split apart to improve docker build cache
#
ADD files /
