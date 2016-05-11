#! /bin/bash -x

echo Entering $0

# Fix cgroup mounts if not already done
#
. /remount_cgroups.sh

## Use overlay storage driver unless user overrides the selection
##
#DOCKER_DAEMON_ARGS=${DOCKER_DAEMON_ARGS:-'-s overlay'}

### Bulk of remaining code taken from https://github.com/jpetazzo/dind
###
# Now, close extraneous file descriptors.
pushd /proc/self/fd >/dev/null
for FD in *
do
	case "$FD" in
	# Keep stdin/stdout/stderr
	[012])
		;;
	# Nuke everything else
	*)
		eval exec "$FD>&-"
		;;
	esac
done
popd >/dev/null

# If a pidfile is still around (for example after a container restart),
# delete it so that docker can start.
#
rm -rf /var/run/docker.pid

# If we were given a DOCKERD_PORT environment variable, start as a simple daemon;
# otherwise, exec out to user defined process or systemd as default
#
if [ "$DOCKERD_PORT" ]; then
	exec docker daemon -H 0.0.0.0:$DOCKERD_PORT -H unix:///var/run/docker.sock \
		$DOCKER_DAEMON_ARGS

else
	if [ "$LOG" == "file" ]
	then
		docker daemon $DOCKER_DAEMON_ARGS &>/var/log/docker.log &
	else
		docker daemon $DOCKER_DAEMON_ARGS &
	fi
	(( timeout = 60 + SECONDS ))
	until docker info >/dev/null 2>&1
	do
		if (( SECONDS >= timeout )); then
			echo 'Timed out trying to connect to internal docker host.' >&2
			break
		fi
		sleep 1
	done
	[[ $1 ]] && exec "$@"
	exec bash --login

fi
