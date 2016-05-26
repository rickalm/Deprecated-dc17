# Create /data directories for any symlinked targets
#
mkdir -p /data/var/log/mesos 2>/dev/null
mkdir -p /data/var/log/mesosphere 2>/dev/null

mkdir -p /data/var/lib/mesos 2>/dev/null
mkdir -p /data/var/lib/mesosphere 2>/dev/null
mkdir -p /data/var/lib/dcos 2>/dev/null
mkdir -p /data/var/lib/zookeeper 2>/dev/null
mkdir -p /data/var/lib/cosmos 2>/dev/null

# Save Mesos Cluster Name
#
[ -n "${MESOS_CUSTER}" ] && echo MESOS_CUSTER=${MESOS_CUSTER} >>${dcos_conf}


# If we DNS configurations, save them
#
[ -n "${RESOLVERS}" ] && echo RESOLVERS=${RESOLVERS} >>${dcos_conf}
[ -n "${SEARCH}" ] && echo SEARCH=${SEARCH} >>${dcos_conf}


# Set DCOS_Datacenter and DCOS_Region incase they are still blank, then save all DCOS_ params to our config file
#
DCOS_DATACENTER=${DCOS_DATACENTER:-DataCenter01}
DCOS_REGION=${DCOS_REGION:-Region01}
cat /proc/self/environ | tr '\0' '\n' | grep '^DCOS_' >>${dcos_conf}


# Disable signal till we figure out how to make it work and if we want it to exist
#
systemctl disable dcos-signal.service


# Enable DCOS services
#
systemctl enable dcos.target
