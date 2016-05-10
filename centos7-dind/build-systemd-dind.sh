#! /bin/bash

rm -rf dind docker-systemd-unpriv target 2>/dev/null

# A better centos-systemd approach was derived from this project
# dbus.service no longer needed, centos repos seem to do this correctly now
#
#git clone https://github.com/maci0/docker-systemd-unpriv.git
#mkdir -p target/etc/systemd/system
#
## Install dbus.service from docker-systemd-unpriv
##
#cp docker-systemd-unpriv/dbus.service target/etc/systemd/system/.
#cat <<EOF >>target/etc/systemd/system/dbus.service
#[Install]
#WantedBy=basic.target
#EOF
#
# No longer needed

# A better DIND approack was devived from this project
#
git clone https://github.com/jpetazzo/dind.git
mkdir -p target/usr/local/bin

# Install wrapdocker script from dind
#
cp dind/wrapdocker target/start_dind.sh

# Trying to 
#cat dind/wrapdocker | sed -ne '1,83p' >target/start_dind.sh
#cat <<EOF >>target/start_dind.sh
#systemctl enable docker.service
#systemctl enable docker.socket
#
#[ -z "\$1" ] && exec /usr/lib/systemd/systemd
#exec \$@
#EOF

chmod +x target/usr/local/bin/start_dind

docker build -f Dockerfile.centos-dind-systemd:7 -t rickalm/centos-dind-systemd:7 .
