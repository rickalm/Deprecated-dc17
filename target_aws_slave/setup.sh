#! /bin/bash

. /service_functions.bash

svc dcos-spartan.service
svc_wants dcos-epmd.service                   # Make sure EPMD is running
svc_starts dcos-spartan-watchdog.timer        # When Spartan starts enable the watchdog timer
svc_sed	"Pre=-*/usr/bin/env ip" "Pre=-/usr/sbin/ip"
svc_sed	"Pre=-*/usr/bin/env modprobe" "Pre=-/usr/sbin/modprobe"

svc dcos-spartan-watchdog.service
svc_needs_spartan                             # No point starting watchdog if Spartan isnt running
svc_rm_dep sleep.60                           # Remove Initial 60 second delay for service

svc dcos-gen-resolvconf.service
svc_rm_dep spartan                            # Remove Dependency on starting Spartan

svc dcos-mesos-slave.service
svc_waitfor_leader                            # Needs to talk to leader.mesos, rather then dying wait for it
svc_starts dcos-gen-resolvconf.service        # Needs mesos-dns
svc_starts dcos-ddt.service                   # Enable Distributed Diagnostics
svc_starts dcos-logrotate.timer               # Enable Log Rotate


rm -rf /opt/mesosphere/active/minuteman
rm -rf /opt/mesosphere/active/keepalived
rm -rf /opt/mesosphere/active/dcos-signal

#systemctl enable dcos-01-startup.service
