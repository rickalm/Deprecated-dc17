#! /bin/sh

echo Launching Mesos Slave

[ -f /setup/common/start.sh ] && . /setup/common/start.sh
[ -f /setup/aws/start.sh ] && . /setup/aws/start.sh

conf_dir=/etc/mesosphere/setup-packages/dcos-provider-uptake--setup

# Check for required Params
#
[ -z "${EXHIBITOR_ADDRESS}" ] && echo "EXHIBITOR_ADDRESS not defined, aborting" && exit 1

# Change the Spartan erlang name so we can run master/slave on same host
#
sed -i -e 's/spartan@127.0.0.1/spartan_slave@127.0.0.1/' /opt/mesosphere/active/spartan/spartan/releases/0.0.1/vm.args

# Write the changes out to the config files
#
sed -i -e '/^EXHIBITOR_ADDRESS/d' ${conf_dir}/etc/dns_config
sed -i -e '/^MASTER_SOURCE/d' ${conf_dir}/etc/dns_config
echo EXHIBITOR_ADDRESS=${EXHIBITOR_ADDRESS} >>${conf_dir}/etc/dns_config
echo MASTER_SOURCE=exhibitor >>${conf_dir}/etc/dns_config

# Source the Mesosphere enviornment before launch
#
set -a; . /opt/mesosphere/environment; set +a
#/opt/mesosphere/bin/pkgpanda setup
