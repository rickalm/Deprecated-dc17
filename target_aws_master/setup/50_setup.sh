svc_rm_dep dcos-mesos-dns.service		dcos-mesos-master.service
svc_needs_zookeeper dcos-mesos-dns.service

svc_needs_zookeeper dcos-oauth.service

svc_needs dcos-cluster-id.service		dcos-exhibitor.service
svc_needs_zookeeper dcos-cluster-id.service

svc_sed dcos-spartan.service			Pre=/ Pre=-/
svc_needs dcos-spartan.service			dcos-epmd.service
svc_needs dcos-spartan.service			dcos-exhibitor.service
svc_starts dcos-spartan.service			dcos-gen-resolvconf.timer
svc_starts dcos-spartan.service			dcos-spartan-watchdog.timer
svc_needs_zookeeper dcos-spartan.service

svc_needs_spartan dcos-spartan-watchdog.service
svc_rm_dep dcos-spartan-watchdog.service	sleep.60

svc_needs_spartan dcos-mesos-master.service
svc_needs_clusterid dcos-mesos-master.service
svc_needs dcos-mesos-master.service		dcos-mesos-dns.service

svc_needs_leader dcos-marathon.service

svc_needs_leader dcos-ddt.service

svc_needs_leader dcos-cosmos.service

svc_needs dcos-adminrouter.service		dcos-oauth.service
svc_needs dcos-adminrouter.service		dcos-cosmos.service
svc_needs dcos-adminrouter.service		dcos-ddt.service
svc_needs dcos-adminrouter.service		dcos-history-service.service
svc_cond_pathexists dcos-adminrouter.service	/opt/mesosphere/etc/adminrouter.env
svc_cond_pathexists dcos-adminrouter.service	/opt/mesosphere/etc/dcos-oauth.env
svc_cond_pathexists dcos-adminrouter.service	/var/lib/dcos/auth-token-secret
svc_needs_marathon dcos-adminrouter.service
svc_starts dcos-adminrouter.service		dcos-logrotate.timer
svc_starts dcos-adminrouter.service		dcos-adminrouter-reload.timer

rm -rf /opt/mesosphere/active/minuteman
rm -rf /opt/mesosphere/active/keepalived
rm -rf /opt/mesosphere/active/dcos-signal
