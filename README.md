## DCOS as a Docker Container


### Launching a DCOS Master

```
docker run --privileged=true --net=host -it -d --name master \
  -v /var/lib/mesos:/data \
  -e 'MESOS_CLUSTER=CLUSTER_NAME' \
  rickalm/dcos:1.7_aws_master
```

Environment Variables that influence the startup

- MESOS_CLUSTER - Name you want your cluster to be known as. Will default to a random name (Based on /dev/urandom)

- MESOS_CLUSTER_SIZE - You can set this to the number of nodes you want in your cluster. If you change this value please be sure to use 3 5 or 7 as the target size. Mesos uses a quorum to maintain HA health and even numbers do not work. Also if you set this value you must provide a way for Exhibitor (Zookeeper) to find its peers. Currently that is limited to using an S3 bucket in this build

- AWS_S3_BUCKET - This is the name of the S3 bucket to store the Exhibitor files in for multi-node setup. The host needs access to this bucket and the easiest way is to create an IAM role and attach it to the hosts running the DCOS Masters.

- AWS_S3_PREFIX - (Default value is "cluster_${MESOS_CLUSTER}") This is the name of the file (and directory) that will be created in the  bucket for Exhibitor. Since the default is created from the cluster name you can actually use the same S3 bucket for more than one cluster.

- AWS_REGION - (Default is discovered via EC2-MetaData service) This is used in the S3 bucket API calls to direct the request to the correct region. If your S3 bucket is not in the same region as your cluster then you will need to set the value



### Launching a DCOS Slave

```
docker run --privileged=true --net=host -it -d --name slave \
  -e 'EXHIBITOR_ADDRESS=127.0.0.1' \
  rickalm/dcos:1.7_aws_slave
```

Environment Variables that influence the startup

- EXHIBITOR_ADDRESS - A list of the Mesos Exhibitor nodes that the slave can use to contact the Mesos Cluster. The easiest (for many reasons) is to create a load balancer (e.g. AWS ELB) that forwards traffic to the availible nodes and provide the address of the ELB here.


### Other details for setting up a cluster

#### Security Groups.
The DCOS AWS Cloud Formation template creates 5 templates that are reasonable sound from a security stance.

- LB-Security-Group - Is an empty group which is the SourceSecurityGroup for the ELB's to allow them to access the nodes in the cluster
  - Inbound: None
  - Outbound: All

- Master-Security-Group - Is applied to Master nodes to control communication to them
  - Inbound:
    - TCP/80 - From LB-Security-Group (DCOS Admin Router)
    - TCP/8080 - From LB-Security-Group (Marathon)
    - TCP/5050 - From LB-Security-Group (Mesos)
    - TCP/2181 - From LB-Security-Group (Zookeeper)
    - TCP/8181 - From LB-Security-Group (Exhbititor)
    - ALL/ALL - From Master-Security-Group
    - ALL/ALL - From Slave-Security-Group

- Slave-Security-Group - Is applied to (NonPublic)Slave Nodes
  - Inbound:
    - ALL/ALL - From Master-Security-Group
    - ALL/ALL - From Slave-Security-Group
    - ALL/ALL - From PublicSlave-Security-Group
  - Outbound: All

- PublicSlave-Security-Group - Is applied to PublicSlave Nodes which have an External IP Address
  - Inbound:
    - ALL/ALL - From Master-Security-Group
    - ALL/ALL - From Slave-Security-Group
    - ALL/ALL - From PublicSlave-Security-Group
    - Add other rules as appropriate for your application
  - Outbound: All

- Admin-Security-Group - Is applied to all nodes in your cluster to allow SysAdmin access to the cluster (e.g. ssh)
  - Inbound:
    - ALL/ALL - Define as needed from your Admin Team's IP addresses
  - Outbound: All

#### Load Balancers (ELB)

- DCOS Cluster Load Balancer. In order for the slaves to access the resources on the Cluster Masters, its recomended to create a LB which the slaves will use to access the cluster. This is not really intended as the way for users to access the cluster, but more as the way for the cluster resources to discover each other
  - Ports to forward
    - 2181 - Zookeeper's RPC/API interface
    - 8181 - Exhibitor's Web UI/API interface
    - 5050 - Mesos's Web/API Interface
    - 8080 - Marathon's Web/API Interface
    - 80 - DCOS's HTTP Web/API Interface
    - 443 - DCOS's HTTPS Web/API Interface
  - Health Check
    - Endpoint - HTTP:5050/health (is mesos healthy)
  - Security
    - LB-Security-Group
    - Master-Security-Group
    - Slave-Security-Group
    - PublicSlave-Security-Group
    - Admin-Security-Group

- DCOS Admin Load Balancer. Used to access the DCOS interface from outside the cluster using the DCOS Cli or the Web Interface 
  - Ports to forward
    - 80 - DCOS's HTTP Web/API Interface
    - 443 - DCOS's HTTPS Web/API Interface
  - Health Check
    - Endpoint - HTTP:5050/health (is mesos healthy)
  - Security
    - LB-Security-Group
    - Admin-Security-Group

