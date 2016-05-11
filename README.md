## DCOS as a Docker Container

### Why Docker container vs Native Install

- Simpler to deploy. The DCOS method of deployment is fractured at the moment as follows:
  - an AWS CloudFormation template that allows "auto-scalling" of resources, deploying the bootstrap loader along with a cloudinit script that customizes about a dozen files in a very hard to read/maintain manner
  - a script that is intended to run from a "bootstrap node" that needs SSH access to all of the already deployed nodes, IP addresses of those hosts and other bits of information. This basically precludes the use of any auto-scale methodoligy

- Upgrade/Downgrade:
  - While the DCOS PkgPanda tool was designed for on-the-fly changes to the environment, it doesn't make it easy to replace files from the base build with customer packages.
  - Knowing whats in your package. This is always important for Change Management it provides a way to create a fixed deplyment to your nodes

- Do as I say, not as I do. How do you convince your developers to create docker containers for their application, yet tell them all of the tools your providing rely on native install

- Creating support for environments where you can't control the Base Image. DCOS requires CentOS 7 or CoreOS 835 or greater but sometimes you have to deploy on older platforms. Rather than create a "Cant be used here" situation, this container is built from the CentOS 7 base image and then corrects for what features are not availible in the Host build (e.g. SystemD/CGroups)


### Launching a DCOS Master

```
docker run --privileged=true --net=host -it -d --name master \
  -v /var/lib/mesos-master:/data \
  -e 'MESOS_CLUSTER=CLUSTER_NAME' \
  rickalm/dcos:1.7_aws_master
```

Volume Mounts

Inside the docker container the /data directory is defined as a volume mount to reduce the amount of data written to the overlayfs filesystem. By specifying a directory on the host, we are able to maintain persistance on the node so if the master needs to be restarted it can use cached information allowing its recovery to be faster.

Environment Variables that influence the startup

- MESOS_CLUSTER - Name you want your cluster to be known as. Will default to a random name (Based on /dev/urandom)
  - written to several places as required by the mesos scripts

- MESOS_CLUSTER_SIZE - You can set this to the number of nodes you want in your cluster. If you change this value please be sure to use 3 5 or 7 as the target size. Mesos uses a quorum to maintain HA health and even numbers do not work. Also if you set this value you must provide a way for Exhibitor (Zookeeper) to find its peers. Currently that is limited to using an S3 bucket in this build

  - Sets the Exhibitor Fixed Ensemble Size variable
  - Computes the value for MESOS_QUORUM as MESOS_CLUSTER_SIZE - 1 (Imperfect, but can always be overridden as a VAR)
  - Enforces S3 bucket configuration for clusters > 1 node 

- AWS_S3_BUCKET - This is the name of the S3 bucket to store the Exhibitor files in for multi-node setup. The host needs access to this bucket and the easiest way is to create an IAM role and attach it to the hosts running the DCOS Masters.

- AWS_S3_PREFIX - (Default value is "cluster_${MESOS_CLUSTER}") This is the name of the file (and directory) that will be created in the  bucket for Exhibitor. Since the default is created from the cluster name you can actually use the same S3 bucket for more than one cluster.

- AWS_REGION - (Default is discovered via EC2-MetaData service) This is used in the S3 bucket API calls to direct the request to the correct region. If your S3 bucket is not in the same region as your cluster then you will need to set the value


### Launching a DCOS Slave

```
docker run --privileged=true --net=host -it -d --name slave \
  -v /var/lib/mesos-slave:/data \
  -e 'EXHIBITOR_ADDRESS=127.0.0.1' \
  rickalm/dcos:1.7_aws_slave
```

The first two volume mounts are there to provide the mesos-slave access to the host's docker environment so it can launch docker containers on the machine

The third volume is identical to the one in the DCOS Master, allowing for persistance on the host so that the slave can resume its responsibilities with the shortest downtime

Environment Variables that influence the startup

- EXHIBITOR_ADDRESS - A list of the Mesos Exhibitor nodes that the slave can use to contact the Mesos Cluster. The easiest (for many reasons) is to create a load balancer (e.g. AWS ELB) that forwards traffic to the availible nodes and provide the address of the ELB here.

  - Note: If EXHIBITOR_ADDRESS is set to 127.0.0.1 it will configure the slave container to disable epmd, spartan, resolvconf, ddt and a few other services which overlap with the mesos-master container so they can co-exist on the same host. 


### Environment Variables for both Master and Slave containers

Any environment variable passed to the container prefixed with the list below will be written to /opt/mesosphere/etc/dcos-docker-environment. This file is included as the last EnvironmentFile= in each dcos-*.service unit file allowing any environment var to be overridden from the "docker run" command without having to track down the files where it is currently set and then perform an on-the-fly re-write of that file. 

- MARATHON
- MESOS
- DCOS
- EXHIBITOR
- OAUTH
- MASTER
- RESOLVER
- AWS

### Other details for setting up a cluster

#### Security Groups
.
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

