# Make sure we have a MESOS_QUORUM, if not compute it for the user
#
if [ "${MESOS_CLUSTER_SIZE}" -gt 1 -a -z "${MESOS_QUORUM}" ]; then
  MESOS_QUORUM=$[${MESOS_CLUSTER_SIZE} - 1]
fi

# If MESOS_CLUSTER_SIZE is greater than 1, make sure S3 bucket is configured
#
if [ "${MESOS_CLUSTER_SIZE}" -gt 1 ]; then
  [ -z "${AWS_S3_BUCKET}" ] && echo "AWS_S3_BUCKET not defined, aborting" && exit 1

  # Configure Exhibitor/Zookeeper environment for a Multinode Cluster
  #
  # region will have already been determined if not defined by the user
  # prefix will be set to cluster_$MESOS_CLUSTER if not defined
  #
  EXHIBITOR_BACKEND=AWS_S3
  AWS_S3_PREFIX=${AWS_S3_PREFIX:-cluster_${MESOS_CLUSTER}}
fi
