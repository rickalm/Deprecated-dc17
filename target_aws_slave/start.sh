#! /bin/sh

echo Launching Mesos Master

conf_dir=/etc/mesosphere/setup-packages/dcos-provider-uptake--setup

# Absorb Environment from init (Yes its a hack, but this way we get any Docker Environment Vars)
#
set -a; eval $(cat /proc/1/environ | tr '\0' '\n'); set +a

# Check for required Params
#
[ -z "${EXHIBITOR_ADDRESS}" ] && echo "EXHIBITOR_ADDRESS not defined, aborting" && exit 1

# If AWS_REGION isnt defined go discover it
#
if [ -z "${AWS_REGION}" ]; then
  AWS_REGION=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/[a-z]$//')
fi

# Write the changes out to the config files
#
sed -i -e '/^EXHIBITOR_ADDRESS/d' ${conf_dir}/etc/dns_config
sed -i -e '/^MASTER_SOURCE/d' ${conf_dir}/etc/dns_config
echo EXHIBITOR_ADDRESS=${EXHIBITOR_ADDRESS} >>${conf_dir}/etc/dns_config
echo MASTER_SOURCE=exhibitor >>${conf_dir}/etc/dns_config

# Source the Mesosphere enviornment before launch
#
set -a; . /opt/mesosphere/environment; set +a
/opt/mesosphere/bin/pkgpanda setup
