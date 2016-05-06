#! /bin/sh

# Define where DCOS is installed
#
dcos_dir=/opt/mesosphere

# Absorb Environment from init (Yes its a hack, but this way we get any Docker Environment Vars)
#
set -a; eval $(cat /proc/1/environ | tr '\0' '\n'); set +a

# Locate docker.sock and link to /var/run/docker.sock
#
sock=$(mount | tr ' ' '\n' | grep docker.sock)"
[ -n "${sock}" -a "${sock}" != "/var/run/docker.sock" ] && ln -s ${sock} /var/run/docker.sock
#! /bin/sh

# Set a default cluster name if not specified
#
MESOS_CLUSTER=${MESOS_CLUSTER:-$(dd status=none count=1 bs=8 if=/dev/urandom | base64)}
MESOS_CLUSTER_SIZE=${MESOS_CLUSTER_SIZE:-1}
