#! /bin/bash

# Anounce ourselves
#
echo Entering $0

# Fix cgroup mounts if not already done
#
. /remount_cgroups.sh

# Close any files other than STDIN, STDOUT and STDERR
#
. /close_fd.sh

# Launch systemd (with optional args from environment variable)
#
exec /usr/lib/systemd/systemd ${SYSTEMD_OPTS}
