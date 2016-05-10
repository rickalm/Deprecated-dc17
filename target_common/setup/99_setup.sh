# Finally run pkgpanda and cleanup after its done
#
set -o allexport; . /opt/mesosphere/environment; set +o allexport
/opt/mesosphere/bin/pkgpanda setup --no-systemd || exit 1

#find /opt/mesosphere -type d -name '*.old' | xargs rm -rf
