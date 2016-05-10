#! /bin/bash

##################################
###
# This project starts from centos:7 build and installs systemd (container) and lastest docker
#
# it then configured cgroups
# launches docker
# passes control to systemd (unless told to do otherwise)
#
#
###
##################################

##################################
###
### Clean up our child directories and fetch repos as needed
###
rm -rf dind docker-systemd-unpriv target 2>/dev/null

########
# A better centos-systemd approach was derived from this project
# git clone https://github.com/maci0/docker-systemd-unpriv.git
#
# dbus.service no longer needed, centos repos seem to do this correctly now
# The approach from the Dockerfile was absorbed into our Dockerfile
#

########
# A better DIND approach was devived from this project
#
git clone https://github.com/jpetazzo/dind.git
mkdir -p target/usr/local/bin
###
##################################




##################################
###
### create fix_cgroups script based on content from wrapdocker script in dind
###
cat <<EOF >target/fix_cgroups.sh
#! /bin/bash

# If /fix_cgroups.done exists then we have already done our job and return
#
[ -f /fix_cgroups.done ] && exit 0

# First half of wrapdocker script to fixup cgroups mounts
#
EOF

### Grab content from wrapdocker we need
###
sed -ne '2,83p' dind/wrapdocker >>target/fix_cgroups.sh

### Add to the end of the script the flag to not run again
###
cat <<EOF >>target/fix_cgroups.sh

# Done, create our flag file so we dont run again
#
touch /fix_cgroups.done
EOF
###
##################################



##################################
###
### create start_dind.sh script based on content from wrapdocker script in dind
###
cat <<EOF >target/start_dind.sh
#! /bin/bash

# Fix cgroup mounts if not already done
#
. /fix_cgroups.sh

# Launch Docker
#
EOF
sed -ne '84,$p' dind/wrapdocker >>target/start_dind.sh
###
##################################




##################################
###
### Create an /entrypoint.sh script
###
cat <<EOF >target/entrypoint.sh
#! /bin/sh

# If no params specified, then chain to systemd
#
[ -z "\$1" ] && exec /start_dind.sh /usr/lib/systemd/systemd
exec /start_dind.sh \$@
EOF
###
##################################


# Make sure out new scripts are marked exec
chmod +x target/start_dind.sh
chmod +x target/fix_groups.sh
chmod +x target/entrypoint.sh

docker build -f Dockerfile.centos-dind-systemd:7 -t rickalm/centos-dind-systemd:7 .
