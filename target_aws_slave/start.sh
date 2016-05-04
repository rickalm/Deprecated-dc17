#! /bin/sh

echo Launching Mesos Master
dcos_config_dir=$(find /opt/mesosphere/packages -name dcos-config--setup*)

# Absorb Environment from init (Yes its a hack, but this way we get any Docker Environment Vars)
#
set -a; eval $(cat /proc/1/environ | tr '\0' '\n'); set +a

# Set a default cluster name if not specified
#
MESOS_CLUSTER=${MESOS_CLUSTER:-$(dd status=none count=1 bs=8 if=/dev/urandom | base64)}
##REA##MESOS_CLUSTER_SIZE=${MESOS_CLUSTER_SIZE:-1}

# If MESOS_CLUSTER_SIZE is greater than 1, make sure S3 bucket is configured
#
##REA##if [ "${MESOS_CLUSTER_SIZE}" -gt 1 ]; then
  ##REA##[ -z "${AWS_S3_BUCKET}" ] && echo "AWS_S3_BUCKET not defined, aborting" && exit 1
##REA##fi

# If AWS_REGION isnt defined go discover it
#
if [ -z "${AWS_REGION}" ]; then
  AWS_REGION=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/[a-z]$//')
fi

# Write the changes out to the config files
#
##REA##echo ${MESOS_CLUSTER_SIZE} >${dcos_config_dir}/etc_master/master_count

echo MESOS_CLUSTER=${MESOS_CLUSTER} >${dcos_config_dir}/etc/mesos-master-provider
##REA##echo MESOS_CLUSTER_SIZE=${MESOS_CLUSTER_SIZE} >>${dcos_config_dir}/etc/mesos-master-provider

##REA##echo AWS_S3_PREFIX=${AWS_S3_PREFIX:-cluster_${MESOS_CLUSTER}} >>${dcos_config_dir}/etc/exhibitor
##REA##echo AWS_S3_BUCKET=${AWS_S3_BUCKET} >>${dcos_config_dir}/etc/exhibitor
##REA##echo AWS_REGION=${AWS_REGION} >>${dcos_config_dir}/etc/exhibitor
##REA##echo EXHIBITOR_BACKEND=AWS_S3 >>${dcos_config_dir}/etc/exhibitor

# Source the Mesosphere enviornment before launch
#
set -a; . /opt/mesosphere/environment; set +a
/opt/mesosphere/bin/pkgpanda setup
