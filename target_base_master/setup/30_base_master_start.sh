# Write Cluster Info to files
#
echo ${MESOS_CLUSTER_SIZE} >${dcos_dir}/etc/master_count
echo MESOS_CLUSTER=${MESOS_CLUSTER} >>${dcos_conf}

if [ "${MESOS_CLUSTER_SIZE}" -gt 1 ]; then
  echo MESOS_QUORUM=$[${MESOS_CLUSTER_SIZE} - 1] >>${dcos_conf}
fi

# If MESOS_CLUSTER_SIZE is greater than 1, make sure S3 bucket is configured
#
if [ "${MESOS_CLUSTER_SIZE}" -gt 1 ]; then
  [ -z "${AWS_S3_BUCKET}" ] && echo "AWS_S3_BUCKET not defined, aborting" && exit 1

  # Configure Exhibitor/Zookeeper environment for a Multinode Cluster
  #
  echo EXHIBITOR_BACKEND=AWS_S3 >>${dcos_conf}
  echo AWS_REGION=${AWS_REGION} >>${dcos_conf}
  echo AWS_S3_PREFIX=${AWS_S3_PREFIX:-cluster_${MESOS_CLUSTER}} >>${dcos_conf}
  echo AWS_S3_BUCKET=${AWS_S3_BUCKET} >>${dcos_conf}
fi
