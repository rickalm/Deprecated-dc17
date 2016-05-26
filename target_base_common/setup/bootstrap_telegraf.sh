set -x

# Install Telegraf tools
#

# Fetch tools and make sure they exist
#
curl -o - https://dl.influxdata.com/telegraf/releases/telegraf-0.13.0_linux_amd64.tar.gz | tar -C /tmp -xzf - || exit 1
test -x /tmp/telegraf-0.13.0-1/usr/bin/telegraf || exit 1

# Change to the source directory
#
pushd /tmp/telegraf-0.13.0-1 2>&1 >/dev/null

# Create telegraf user and provide access to docker sock
#
useradd -G docker telegraf

# create directories needed
#
install -d /etc/telegraf/telegraf.d || exit 1

# Install required files
#
install -D etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf || exit 1
install -D etc/logrotate.d/telegraf /etc/logrotate.d/telegraf || exit 1
install -D usr/bin/telegraf /usr/bin/telegraf || exit 1
install -D usr/lib/telegraf/scripts/telegraf.service /usr/lib/telegraf/scripts/telegraf.service || exit 1

# Add our environment file to the systemd script for telegraf
#
sed -i -e '/[Install]/i EnvironmentFile=-/opt/mesosphere/etc/dcos-docker.env' /usr/lib/telegraf/scripts/telegraf.service

# Symlink the telegraf log dir to our volume mount
#
ln -s /data/var/log/telegraf /var/log/telegraf || exit 1

# Be kind, rewind
#
popd 2>&1 >/dev/null
