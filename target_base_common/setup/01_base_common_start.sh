#! /bin/sh

# Define where DCOS is installed
#
dcos_dir=/opt/mesosphere
dcos_conf=/opt/mesosphere/etc/dcos-docker-environment

# Absorb Environment from init (Yes its a hack, but this way we get any Docker Environment Vars)
# Also write it to dcos_conf so services can absorb it on launch
#
cat /proc/1/environ | tr '\0' '\n' | egrep '^(MARATHON|MESOS|DCOS|EXHIBITOR|OAUTH|MASTER|RESOLVER|AWS)' >${dcos_conf}
set -o allexport; . ${dcos_conf}; set +o allexport

# Set a default cluster name if not specified
#
MESOS_CLUSTER=${MESOS_CLUSTER:-$(dd status=none count=1 bs=8 if=/dev/urandom | base64)}
MESOS_CLUSTER_SIZE=${MESOS_CLUSTER_SIZE:-1}
