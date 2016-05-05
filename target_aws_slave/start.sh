#! /bin/sh

echo Launching Mesos Master

dcos_config_dir=$(find /opt/mesosphere/packages -name dcos-config--setup*)
aws_conf_dir=/etc/mesosphere/setup-packages/dcos-provider-aws--setup

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
echo EXHIBITOR_ADDRESS=${EXHIBITOR_ADDRESS} >>${aws_config_dir}/etc/dns_config

# Source the Mesosphere enviornment before launch
#
set -a; . /opt/mesosphere/environment; set +a
/opt/mesosphere/bin/pkgpanda setup
