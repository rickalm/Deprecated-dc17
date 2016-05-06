#! /bin/bash

# Load our Setup Functions
#
. /setup/service_functions.sh

# Run each setup script in order
#
find /setup/ -name *_setup.sh | sort | while read line; do echo . $line >>/tmp/setup.loader; done
. /tmp/setup.loader
rm /tmp/setup.loader

# Finally run pkgpanda and cleanup after its done
#
set -a; . /opt/mesosphere/environment; set +a
/opt/mesosphere/bin/pkgpanda setup --no-systemd

find /opt/mesosphere -name '*.old' | xargs rm -rf
