# Check for required Params
#
[ -z "${EXHIBITOR_ADDRESS}" ] && echo "EXHIBITOR_ADDRESS not defined, aborting" && exit 1

# Update dns_config to use the master exhibitor
#
sed -i -e '/^EXHIBITOR_ADDRESS/d' ${dcos_dir}/etc/dns_config
sed -i -e '/^MASTER_SOURCE/d' ${dcos_dir}/etc/dns_config
echo EXHIBITOR_ADDRESS=${EXHIBITOR_ADDRESS} >>${dcos_dir}/etc/dns_config
echo MASTER_SOURCE=exhibitor >>${dcos_dir}/etc/dns_config

# Turn off CGroup support in slave till we figure out work-around (Fixed with centos-dind-systemd image)
#
#sed -i -e '/^MESOS_ISOLATION/d' ${dcos_dir}/etc/mesos-slave-common
#echo MESOS_ISOLATION=posix/cpu,posix/mem,posix/disk >>${dcos_dir}/etc/mesos-slave-common

# Turn off SystemD support in slave till we figure out work-around
#
echo MESOS_SYSTEMD_ENABLE_SUPPORT=false >>${dcos_dir}/etc/mesos-slave-common

# Disable Minuteman till iptables issues are figured out
#
systemctl disable dcos-minuteman.service

# Disable remote reporter till we review what data is shared
#
systemctl disable dcos-signal.timer

# If EXHIBITOR_ADDRESS is localhost, then this slave is running on the same host as a Master
#
if [ "${EXHIBITOR_ADDRESS}" == "127.0.0.1" -o "${EXHIBITOR_ADDRESS}" == "localhost" ]; then
  systemctl disable dcos-epmd.service
  systemctl disable dcos-ddt.service
  systemctl disable dcos-spartan.service
  systemctl disable dcos-spartan-watchdog.service
  systemctl disable dcos-spartan-watchdog.timer
fi
