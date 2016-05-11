svc dcos-mesos-dns.service
svc_needs_zookeeper 

svc dcos-oauth.service
svc_needs_zookeeper

svc dcos-cluster-id.service
svc_needs_zookeeper

svc dcos-spartan.service
svc_sed Pre=/ Pre=-/
svc_needs dcos-epmd.service
svc_starts dcos-gen-resolvconf.timer
svc_starts dcos-spartan-watchdog.timer
svc_waitfor_zookeeper 

svc dcos-spartan-watchdog.service
svc_needs_spartan
svc_rm_line 'sleep.*60'

svc dcos-mesos-master.service
svc_needs_spartan
svc_needs_clusterid

svc dcos-marathon.service
svc_needs_leader

svc dcos-ddt.service
svc_needs_leader

svc dcos-cosmos.service
svc_needs_leader

svc dcos-adminrouter.service
svc_needs_marathon 
svc_needs dcos-oauth.service
svc_needs dcos-cosmos.service
svc_needs dcos-ddt.service
svc_needs dcos-history-service.service
svc_cond_pathexists /opt/mesosphere/etc/adminrouter.env
svc_cond_pathexists /opt/mesosphere/etc/dcos-oauth.env
svc_cond_pathexists /var/lib/dcos/auth-token-secret
svc_starts dcos-logrotate.timer
svc_starts dcos-adminrouter-reload.timer
