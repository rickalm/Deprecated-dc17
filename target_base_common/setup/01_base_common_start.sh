# Define where DCOS is installed
#
dcos_dir=/opt/mesosphere
dcos_conf=${dcos_dir}/etc/dcos-docker.env


# Absorb Environment from PID-1 (Yes its a hack, but this way we get any Docker Environment Vars)
# Also write it to dcos_conf so services can absorb it on launch
#
cat /proc/1/environ | tr '\0' '\n' \
  | egrep '^(MARATHON|MESOS|DCOS|EXHIBITOR|OAUTH|MASTER|RESOLVERS|SEARCH|AWS)' >${dcos_conf}


# Re-Absorb them into our environment, so we can make decisions based on them
#
set -o allexport; . ${dcos_conf}; set +o allexport


# Set a default cluster name if not specified
# Set Cluster Size to 1 if not defined
#
MESOS_CLUSTER=${MESOS_CLUSTER:-$(dd status=none count=1 bs=8 if=/dev/urandom | base64)}
MESOS_CLUSTER_SIZE=${MESOS_CLUSTER_SIZE:-1}


# If DNS vars were not defined, get the info from the /etc/resolv.conf file passed to us by docker
#
RESOLVERS=${RESOLVERS:-$(grep ^nameserver /etc/resolv.conf | awk '{print $2}' | tr ' ' ',')}
SEARCH=${SEARCH:-$(grep ^search /etc/resolv.conf | awk '{print $2}')}
