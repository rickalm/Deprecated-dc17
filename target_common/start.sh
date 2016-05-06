#! /bin/sh

# Run each start script in order
#
find /setup/ -name *_start.sh | sort >/tmp/start.loader
. /tmp/start.loader
rm /tmp/start.loader

# Pass control to systemd
#
exec /usr/sbin/init
