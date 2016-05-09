#! /bin/sh

# Create /data directories for any symlinked targets
#
mkdir -p /data/var/log/mesos 2>/dev/null
mkdir -p /data/var/log/mesosphere 2>/dev/null

mkdir -p /data/var/lib/mesos 2>/dev/null
mkdir -p /data/var/lib/mesosphere 2>/dev/null
mkdir -p /data/var/lib/dcos 2>/dev/null
mkdir -p /data/var/lib/zookeeper 2>/dev/null
mkdir -p /data/var/lib/cosmos 2>/dev/null

# Write the changes out to the config files
#
echo DCOS_DATACENTER=${DCOS_DATACENTER:-DataCenter01} >>${dcos_dir}/etc/environment
echo DCOS_REGION=${DCOS_REGION:-Region01} >>${dcos_dir}/etc/environment

echo ${MESOS_CLUSTER_SIZE} >${dcos_dir}/etc/master_count
echo MESOS_CLUSTER=${MESOS_CLUSTER} >>${dcos_dir}/etc/mesos-master

if [ "${MESOS_CLUSTER_SIZE}" -gt 1 ]; then
  echo MESOS_QUORUM=$[${MESOS_CLUSTER_SIZE} - 1] >>${dcos_dir}/etc/mesos-master
fi

# Mount /tmp to a ramdisk to reduce overlayfs writes
#
mount -t tmpfs -o size=256M tmpfs /tmp

# Enable DCOS services
#
systemctl enable dcos.target
