#! /bin/sh

# Create /data directories for files
#
mkdir -p /data/var/log/mesos 2>/dev/null
mkdir -p /data/var/log/mesosphere 2>/dev/null

mkdir -p /data/var/lib/mesos 2>/dev/null
mkdir -p /data/var/lib/mesosphere 2>/dev/null
mkdir -p /data/var/lib/dcos 2>/dev/null
mkdir -p /data/var/lib/zookeeper 2>/dev/null
mkdir -p /data/var/lib/cosmos 2>/dev/null

conf_dir=/etc/mesosphere/setup-packages/dcos-provider-uptake--setup

# Absorb Environment from init (Yes its a hack, but this way we get any Docker Environment Vars)
#
set -a; eval $(cat /proc/1/environ | tr '\0' '\n'); set +a

# If AWS_REGION isnt defined go discover it
#
if [ -z "${AWS_REGION}" ]; then
  AWS_REGION=$(curl -sS http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/[a-z]$//')
fi

# Locate docker.sock and link to /var/run/docker.sock
#
[ -n "$(mount | tr ' ' '\n' | grep docker.sock)" ] && ln -s $(mount | tr ' ' '\n' | grep docker.sock) /var/run/docker.sock
