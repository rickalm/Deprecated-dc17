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

### Bulk of remaining code taken from https://github.com/jpetazzo/dind
###

# If a pidfile is still around (for example after a container restart),
# delete it so that docker can start.
#
rm -rf /var/run/docker.pid

# If we were given a DOCKERD_PORT environment variable, pass control to dockerd (exec) so its pid 1
# otherwise:
#  - launch dockerd as a process (with logging)
#  - pass control (exec) user defined process if supplied ($@)
#  - pass control to systemd
#

[ "$DOCKERD_PORT" ] && exec docker daemon -H unix:///var/run/docker.sock -H 0.0.0.0:$DOCKERD_PORT $DOCKER_DAEMON_ARGS

# Launch dockerd as a daemon
#
[ -d /var/log/docker ] || mkdir -p /var/log/docker
docker daemon -H unix:///var/run/docker.sock $DOCKER_DAEMON_ARGS &>/var/log/docker/docker.log &

# Set timeout 60 seconds from now
#
(( timeout = 60 + SECONDS ))
until docker info >/dev/null 2>&1; do
  if (( SECONDS >= timeout )); then
    echo 'Timed out trying to connect to internal docker host.' >&2
    exit 1
  fi

  # Sleep for 3 seconds, (not sleep 1) so we dont spin too fast
  #
  sleep 3
done

# If we were given a command line, pass control to it
#
[[ $1 ]] && exec $@

# Otherwise launch systemd (with optional args from environment variable)
#
exec /usr/lib/systemd/systemd ${SYSTEMD_OPTS}
