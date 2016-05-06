#! /bin/sh

. /setup/common/start.sh
[ -f /setup/aws/start.sh ] && . /setup/aws/start.sh

echo Launching Mesos Master
dcos_config_dir=$(find /opt/mesosphere/packages -name dcos-config--setup*)

# Set a default cluster name if not specified
#
MESOS_CLUSTER=${MESOS_CLUSTER:-$(dd status=none count=1 bs=8 if=/dev/urandom | base64)}
MESOS_CLUSTER_SIZE=${MESOS_CLUSTER_SIZE:-1}

# If MESOS_CLUSTER_SIZE is greater than 1, make sure S3 bucket is configured
#
if [ "${MESOS_CLUSTER_SIZE}" -gt 1 ]; then
  [ -z "${AWS_S3_BUCKET}" ] && echo "AWS_S3_BUCKET not defined, aborting" && exit 1
fi

# Write the changes out to the config files
#
echo ${MESOS_CLUSTER_SIZE} >${dcos_config_dir}/etc_master/master_count

echo MESOS_CLUSTER=${MESOS_CLUSTER} >${dcos_config_dir}/etc/mesos-master-provider
echo MESOS_CLUSTER_SIZE=${MESOS_CLUSTER_SIZE} >>${dcos_config_dir}/etc/mesos-master-provider

echo AWS_S3_PREFIX=${AWS_S3_PREFIX:-cluster_${MESOS_CLUSTER}} >>${dcos_config_dir}/etc/exhibitor
echo AWS_S3_BUCKET=${AWS_S3_BUCKET} >>${dcos_config_dir}/etc/exhibitor
echo AWS_REGION=${AWS_REGION} >>${dcos_config_dir}/etc/exhibitor
echo EXHIBITOR_BACKEND=AWS_S3 >>${dcos_config_dir}/etc/exhibitor

# Source the Mesosphere enviornment before launch
#
set -a; . /opt/mesosphere/environment; set +a
/opt/mesosphere/bin/pkgpanda setup
