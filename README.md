# DCOS as a Docker Container


# Launching a DCOS Master

```
docker run --privileged=true --name master --net=host -d -it \
  -v /var/lib/mesos:/data \
  -e 'MESOS_CLUSTER=CLUSTER_NAME' \
  rickalm/dcos:1.7_aws_master
```

Environment Variables that influence the startup

- MESOS_CLUSTER_SIZE - You can set this to the number of nodes you want in your cluster. If you change this value please be sure to use 3 5 or 7 as the target size. Mesos uses a quorum to maintain HA health and even numbers do not work. Also if you set this value you must provide a way for Exhibitor (Zookeeper) to find its peers. Currently that is limited to using an S3 bucket in this build

- AWS_S3_BUCKET - This is the name of the S3 bucket to store the Exhibitor files in for multi-node setup. The host needs access to this bucket and the easiest way is to create an IAM role and attach it to the hosts running the DCOS Masters.

- AWS_S3_PREFIX - (Default value is "cluster_${MESOS_CLUSTER}") This is the name of the file (and directory) that will be created in the  bucket for Exhibitor. Since the default is created from the cluster name you can actually use the same S3 bucket for more than one cluster.

- AWS_REGION - (Default is discovered via EC2-MetaData service) This is used in the S3 bucket API calls to direct the request to the correct region. If your S3 bucket is not in the same region as your cluster then you will need to set the value



= Launching a DCOS Slave

