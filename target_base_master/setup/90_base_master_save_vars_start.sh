# Save the Mesos Cluster Size Params
#
[ -n "${MESOS_QUORUM}" ] && echo MESOS_QUORUM=${MESOS_QUORUM} >>${dcos_conf}
[ -n "${MESOS_CLUSTER_SIZE}" ] && echo MESOS_CLUSTER_SIZE=${MESOS_CLUSTER_SIZE} >>${dcos_conf}


# Mesos-Master also seems to want the cluster size in a seperate file
#
[ -n "${MESOS_CLUSTER_SIZE}" ] && echo ${MESOS_CLUSTER_SIZE} >${dcos_dir}/etc/master_count


# Save the Exhibitor related params if they have been set
#
[ -n "${EXHIBITOR_BACKEND}" ] && echo EXHIBITOR_BACKEND=${EXHIBITOR_BACKEND} >>${dcos_conf}
[ -n "${AWS_REGION}" ] && echo AWS_REGION=${AWS_REGION} >>${dcos_conf}
[ -n "${AWS_S3_PREFIX}" ] && echo AWS_S3_PREFIX=${AWS_S3_PREFIX} >>${dcos_conf}
[ -n "${AWS_S3_BUCKET}" ] && echo AWS_S3_BUCKET=${AWS_S3_BUCKET} >>${dcos_conf}
