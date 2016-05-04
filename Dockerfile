#FROM centos:centos7.2.1511
#RUN yum clean all && yum swap fakesystemd systemd && yum install -y less iproute

FROM centos:latest
RUN yum clean all && yum install -y less iproute

# Delete most systemd services
#
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
  rm -f /lib/systemd/system/multi-user.target.wants/*;\
  rm -f /etc/systemd/system/*.wants/*;\
  rm -f /lib/systemd/system/local-fs.target.wants/*; \
  rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
  rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
  rm -f /lib/systemd/system/basic.target.wants/*;\
  rm -f /lib/systemd/system/anaconda.target.wants/*;

VOLUME [ "/sys/fs/cgroup" ]
CMD [ "/usr/sbin/init" ]

# Install DCOS 1.7 bootstrap
#
RUN mkdir -p /opt/mesosphere; /usr/bin/curl -fLsSv --retry 20 -Y 100000 -y 60 -o - \
  https://downloads.mesosphere.com/dcos/EarlyAccess/bootstrap/a31ed4c418a9d0d55d5304171e1ac2fce4ddc797.bootstrap.tar.xz \
  | tar -C /opt/mesosphere -Jxf -

# Fix issue with os.rename not working in docker container
#
RUN sed -i -e 's/os.rename(active, old_path)/os.system("mv "+active+" "+old_path)/' \
  /opt/mesosphere/lib/python3.4/site-packages/pkgpanda/__init__.py

# Make Spartan PreExec statements optional
#
RUN sed -i -e 's~Pre=/~Pre=-/~' /opt/mesosphere/packages/spartan--563498f7965d5f52ca63b27235933505d1af255d/dcos.target.wants/dcos-spartan.service 

RUN \
  mkdir -p /etc/profile.d; \
  mkdir -p /etc/mesosphere/setup-flags; \
  /usr/bin/ln -sf /opt/mesosphere/environment.export /etc/profile.d/dcos.sh; \
  echo BOOTSTRAP_ID=a31ed4c418a9d0d55d5304171e1ac2fce4ddc797 >/etc/mesosphere/setup-flags/bootstrap-id; \
  echo https://downloads.mesosphere.com/dcos/EarlyAccess >/etc/mesosphere/setup-flags/repository-url

RUN \
  mkdir -p /etc/systemd/journald.conf.d; \
  echo '[Journal]' >/etc/systemd/journald.conf.d/dcos.conf; \
  echo 'MaxLevelConsole=warning' >>/etc/systemd/journald.conf.d/dcos.conf; \
  \
  mkdir -p /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc; \
  echo '{}' >/etc/mesosphere/setup-packages/dcos-provider-aws--setup/pkginfo.json; \
  \
  echo MASTER_SOURCE=exhibitor >/etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/dns_config; \
  echo EXHIBITOR_ADDRESS=localhost >>/etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/dns_config; \
  echo RESOLVERS=169.254.169.253 >>/etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/dns_config; \
  \
  echo ADMINROUTER_ACTIVATE_AUTH_MODULE=false >/etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/adminrouter.env; \
  \
  echo EXHIBITOR_BACKEND=AWS_S3 >/etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/exhibitor; \
  echo AWS_REGION=us-west-2 >>/etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/exhibitor; \
  echo AWS_S3_BUCKET=d17-exhibitorbucket-16kxi4haxfe6l >>/etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/exhibitor; \
  echo AWS_S3_PREFIX=rick >>/etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/exhibitor; \
  \
  echo MESOS_CLUSTER=rick >/etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/mesos-master-provider; \
  \
  echo rick >/etc/mesosphere/cluster-id


# Three Master Config
#
#RUN echo '[' >/etc/mesosphere/setup-flags/cluster-packages.json; \
#  echo '"dcos-config--setup_ba37b469d77bdf76021c74cfd78c50dd8d091b90",' >>/etc/mesosphere/setup-flags/cluster-packages.json; \
#  echo '"dcos-metadata--setup_ba37b469d77bdf76021c74cfd78c50dd8d091b90"' >>/etc/mesosphere/setup-flags/cluster-packages.json; \
#  echo ']' >>/etc/mesosphere/setup-flags/cluster-packages.json

# Single Master Config
#
RUN \
  echo '[' >/etc/mesosphere/setup-flags/cluster-packages.json; \
  echo '"dcos-config--setup_45a8974c28d1f2a890628bdcff057261195b1aa2",' >>/etc/mesosphere/setup-flags/cluster-packages.json; \
  echo '"dcos-metadata--setup_45a8974c28d1f2a890628bdcff057261195b1aa2"' >>/etc/mesosphere/setup-flags/cluster-packages.json; \
  echo ']' >>/etc/mesosphere/setup-flags/cluster-packages.json

RUN \
  mkdir -p /etc/mesosphere/roles; \
  touch /etc/mesosphere/roles/master; \
  touch /etc/mesosphere/roles/aws_master; \
  touch /etc/mesosphere/roles/aws

RUN groupadd nogroup
ADD ui-config.json /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc

#RUN curl -qSLo - \
#  https://downloads.mesosphere.com/dcos/EarlyAccess/packages/dcos-config/dcos-config--setup_45a8974c28d1f2a890628bdcff057261195b1aa2.tar.xz \
#  | tar -C /opt/mesosphere -Jxf -
#
#RUN curl -qSLo - \
#  https://downloads.mesosphere.com/dcos/EarlyAccess/packages/dcos-metadata/dcos-metadata--setup_45a8974c28d1f2a890628bdcff057261195b1aa2.tar.xz \
#  | tar -C /opt/mesosphere -Jxf -

RUN mkdir -p /etc/selinux/targeted/contexts/
RUN echo '<busconfig><selinux></selinux></busconfig>' > /etc/selinux/targeted/contexts/dbus_contexts

