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
echo DCOS_DATACENTER=${DCOS_DATACENTER:-DataCenter01} >>${dcos_conf}
echo DCOS_REGION=${DCOS_REGION:-Region01} >>${dcos_conf}

# Disable minuteman and signal till we figure out how to make them work
#
systemctl disable dcos-minuteman.service
systemctl disable dcos-signal.service

# Enable DCOS services
#
systemctl enable dcos.target
