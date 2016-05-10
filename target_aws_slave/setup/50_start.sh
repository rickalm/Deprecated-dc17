# Check for required Params
#
[ -z "${EXHIBITOR_ADDRESS}" ] && echo "EXHIBITOR_ADDRESS not defined, aborting" && exit 1

# Change the Spartan erlang name so we can run master/slave on same host
#
#sed -i -e 's/spartan@127.0.0.1/spartan_slave@127.0.0.1/' /opt/mesosphere/active/spartan/spartan/releases/0.0.1/vm.args

# Write the changes out to the config files
#
sed -i -e '/^EXHIBITOR_ADDRESS/d' ${dcos_dir}/etc/dns_config
sed -i -e '/^MASTER_SOURCE/d' ${dcos_dir}/etc/dns_config
echo EXHIBITOR_ADDRESS=${EXHIBITOR_ADDRESS} >>${dcos_dir}/etc/dns_config
echo MASTER_SOURCE=exhibitor >>${dcos_dir}/etc/dns_config

# Turn off SystemD/CGroup support in slave till we figure out work-around
#
sed -i -e '/^MESOS_ISOLATION/d' ${dcos_dir}/etc/mesos-slave-common
echo MESOS_ISOLATION=posix/cpu,posix/mem,posix/disk >>${dcos_dir}/etc/mesos-slave-common
echo MESOS_SYSTEMD_ENABLE_SUPPORT=false >>${dcos_dir}/etc/mesos-slave-common

#systemctl disable dcos-vol-discovery-priv-agent.service
systemctl disable dcos-signal.timer
systemctl disable dcos-minuteman.service
