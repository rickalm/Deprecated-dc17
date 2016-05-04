#! /bin/bash

find_file() {
  find /opt/mesosphere/packages -name $1
}

get_pkg_id() {
  basename $(find /opt/mesosphere/packages -maxdepth 1 -name $1*)
}

add_to_unit() {
  grep -qi "^$2" $(find_file $1) || sed -i -e "/\\[Unit\\]/a$2=" $(find_file $1)
  sed -i -e "/^$2/I s~\$~ $3~" $(find_file $1)
  sed -i -e 's~= ~=~' $(find_file $1)
}

append_to_unit() {
  sed -i -e "/\\[Unit\\]/a$2=$3" $(find_file $1)
}

svc_sed() {
  sed -i -e "s~$2~$3~" $(find_file $1)
}

svc_needs() {
  add_to_unit $1 Requires $2
  add_to_unit $1 After $2
}

svc_starts() {
  add_to_unit $1 Requires $2
  add_to_unit $1 Before $2
}

svc_add_prestart() {
  local name=$1; shift
  echo /\\[Service\\]/aExecStartPre=$@ >/tmp/$$.sed
  sed -i -f /tmp/$$.sed $(find_file $name)
  rm /tmp/$$.sed
}

svc_append() {
  echo $2 >>$(find_file $1)
}

svc_rm_dep() {
  sed -i -e "/$2/d" $(find_file $1)
}

svc_cond_pathexists() {
  append_to_unit $1 ConditionPathExists $2
}

svc_remove_old_deps() {
  svc_rm_dep $1		exhibitor_wait
  svc_rm_dep $1		'ping .* ready.spartan'
  svc_rm_dep $1		'ping .* leader.mesos'
  svc_rm_dep $1		'ping .* marathon.mesos'
}

svc_needs_zookeeper() {
  svc_remove_old_deps $1
  svc_add_prestart $1	/opt/mesosphere/bin/wait_for_zookeeper.sh
  svc_needs $1		dcos-exhibitor.service
}

svc_needs_spartan() {
  svc_remove_old_deps $1
  svc_needs $1		dcos-spartan.service
  svc_add_prestart $1	/opt/mesosphere/bin/wait_till_ping.sh ready.spartan
}

svc_needs_leader() {
  svc_remove_old_deps $1
  svc_needs $1		dcos-mesos-master.service
  svc_add_prestart $1	/opt/mesosphere/bin/wait_till_ping.sh leader.mesos
}

svc_needs_marathon() {
  svc_remove_old_deps $1
  svc_needs $1		dcos-marathon.service
  svc_add_prestart $1	/opt/mesosphere/bin/wait_till_ping.sh marathon.mesos
}

svc_needs_clusterid() {
  svc_needs $1			dcos-cluster-id.service
  svc_rm_dep $1			var.lib.dcos.cluster-id
  svc_cond_pathexists $1	/var/lib/dcos/cluster-id
}

svc_needs_file() {
  #svc_add_prestart $1	/opt/mesosphere/bin/wait_for_file.sh $2
  svc_add_prestart $1	/usr/bin/test -f $2
}

dcos_config_dir=$(find /opt/mesosphere/packages -name dcos-config--setup*)

touch ${dcos_config_dir}/bin/wait_till_ping.sh
chmod +x ${dcos_config_dir}/bin/wait_till_ping.sh
cat <<EOF >>${dcos_config_dir}/bin/wait_till_ping.sh
#! /bin/sh
until ping -c 1 \$1 || /bin/false; do
  sleep 1
done
EOF

touch ${dcos_config_dir}/bin/wait_for_zookeeper.sh
chmod +x ${dcos_config_dir}/bin/wait_for_zookeeper.sh
cat <<EOF >>${dcos_config_dir}/bin/wait_for_zookeeper.sh
#! /bin/sh
until /opt/mesosphere/bin/exhibitor_wait.py; do
  sleep 1
done
EOF

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

#add_to_unit dcos-adminrouter-reload.service   RemainAfterExit yes
#add_to_unit dcos-cluster-id.service           RemainAfterExit yes
#add_to_unit dcos-gen-resolvconf.service       RemainAfterExit yes
#add_to_unit dcos-logrotate.service            RemainAfterExit yes
#add_to_unit dcos-spartan-watchdog.service     RemainAfterExit yes

rm -rf /opt/mesosphere/active/minuteman
rm -rf /opt/mesosphere/active/keepalived
rm -rf /opt/mesosphere/active/dcos-signal

systemctl enable dcos-01-startup.service
