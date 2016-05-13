# Install Filesystem & Networking tools we will need
#
yum -y update || exit 1
yum -y install e2fsprogs net-tools iproute which sudo || exit 1
yum -y clean all || exit 1

# Install JQ tools
#
curl -sSLo /usr/bin/jq  https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 || exit 1
test -f /usr/bin/jq || exit 1
chmod +x /usr/bin/jq || exit 1

# Install Rexray
#
curl -sSL https://dl.bintray.com/emccode/rexray/install | sh - || exit 1
test -x /usr/bin/rexray || exit 1

# Install DVDIcli for mesos
#
curl -sSL https://dl.bintray.com/emccode/dvdcli/install | sh - || exit 1
test -x /usr/bin/dvdcli || exit 1
