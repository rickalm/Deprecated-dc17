svc dcos-spartan.service
svc_wants dcos-epmd.service                           # Try to start epmd if not running
svc_starts dcos-spartan-watchdog.timer                # When Spartan starts enable the watchdog timer

# Make loading the spartan dummy network device optional
#
svc_sed	"Pre=-*/usr/bin/env ip" "Pre=-/usr/sbin/ip"
svc_sed	"Pre=-*/usr/bin/env modprobe" "Pre=-/usr/sbin/modprobe"

svc dcos-gen-resolvconf.service
svc_rm_line spartan                                   # Remove Dependency on starting Spartan

svc dcos-mesos-slave.service
svc_waitfor_leader                                    # Needs to talk to leader.mesos, rather then dying wait for it
svc_needs dcos-vol-discovery-priv-agent.service       # Needs the mesos-resources file to be created
svc_wants dcos-spartan.service                        # Start Spartan if not running already (Hybrid Master/Slave Node)
svc_starts dcos-gen-resolvconf.service                # When Spartan is ready update DNS
svc_starts dcos-logrotate.timer                       # Enable Log Rotate
