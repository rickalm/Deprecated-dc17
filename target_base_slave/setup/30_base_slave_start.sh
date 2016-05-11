# Check for required Params
#
[ -z "${EXHIBITOR_ADDRESS}" ] && echo "EXHIBITOR_ADDRESS not defined, aborting" && exit 1


# Update dns_config to use the master exhibitor
#
echo EXHIBITOR_ADDRESS=${EXHIBITOR_ADDRESS} >>${dcos_conf}
echo MASTER_SOURCE=exhibitor >>${dcos_conf}


# Turn off CGroup support in slave till we figure out work-around (Fixed with centos-dind-systemd image)
#
#echo MESOS_ISOLATION=posix/cpu,posix/mem,posix/disk >>${dcos_conf}


# Turn off SystemD support in slave till we figure out work-around
#
echo MESOS_SYSTEMD_ENABLE_SUPPORT=false >>${dcos_conf}


# If EXHIBITOR_ADDRESS is localhost, then this slave is running on the same host as a Master
#
if [ "${EXHIBITOR_ADDRESS}" == "127.0.0.1" -o "${EXHIBITOR_ADDRESS}" == "localhost" ]; then
  systemctl disable dcos-epmd.service
  systemctl disable dcos-ddt.service
  systemctl disable dcos-spartan.service
  systemctl disable dcos-spartan-watchdog.service
  systemctl disable dcos-spartan-watchdog.timer
fi
