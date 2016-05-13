# If AWS_ZONE or AWS_REGION arnt defined go figure it out
#
AWS_ZONE=${AWS_ZONE:-$(curl -sS http://169.254.169.254/latest/meta-data/placement/availability-zone)}
AWS_REGION=${AWS_REGION:-$(echo ${AWS_ZONE} | sed -e 's/[a-z]$//')}


# If DCOS_ vars arnt defined, use the discovered AWS_ params
#
DCOS_DATACENTER=${DCOS_DATACENTER:-${AWS_ZONE}}
DCOS_REGION=${DCOS_REGION:-${AWS_REGION}}


# Find a random port to assign to RexRay
#
read LOWERPORT UPPERPORT < /proc/sys/net/ipv4/ip_local_port_range
while :; do
  PORT="`shuf -i $LOWERPORT-$UPPERPORT -n 1`"
  ss -lpn | grep -q ":$PORT " || break
done


# Create a Rexray config file
#
mkdir -p /etc/rexray
cat <<EOF >>/etc/rexray/config.yml
rexray:
  host: tcp://127.0.0.1:${PORT}
  modules:
    default-admin:
      host: tcp://127.0.0.1:${PORT}
  osDrivers:
  - linux
  storageDrivers:
  - ec2
  volumeDrivers:
  - docker
aws:
  rexrayTag: ${MESOS_CLUSTER}
EOF

# Inform SystemD to start Rexray as part of DCOS
#
echo WantedBy=dcos.target >>/etc/systemd/system/rexray.service
systemctl enable rexray


# Create /dev/xvd devices till we figure out how to do with hotplug
#
for i in $(seq 0 15); do
  devname=/dev/xvd$(printf "\x$(printf %x $[$i+97])")
  mknod -m 660 ${devname} b 202 $[$i*16]
  mkown root:disk ${devname}
done


