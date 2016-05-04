
/opt/mesosphere/bin/pkgpanda setup --no-systemd

add_to_unit() {
  grep -qi "^$2" /etc/systemd/system/$1 || sed -i -e "/\\[Unit\\]/a$2=" /etc/systemd/system/$1
  sed -i -e "/^$2/I s~\$~ $3~" /etc/systemd/system/$1
  sed -i -e 's/= /=/' /etc/systemd/system/$1
}

append_to_unit() {
  sed -i -e "/\\[Unit\\]/a$2=$3" /etc/systemd/system/$1
}

svc_sed() {
  sed -i -e "s/$2/$3/" /etc/systemd/system/$1
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
  sed -i -f /tmp/$$.sed /etc/systemd/system/$name
  rm /tmp/$$.sed
}

svc_append() {
  echo $2 >>/etc/systemd/system/$1
}

svc_rm_dep() {
  sed -i -e "/$2/d" /etc/systemd/system/$1
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

touch /opt/mesosphere/bin/wait_till_ping.sh
chmod +x /opt/mesosphere/bin/wait_till_ping.sh
cat <<EOF >>/opt/mesosphere/bin/wait_till_ping.sh
#! /bin/sh
until ping -c 1 \$1 || /bin/false; do
  sleep 1
done
EOF

touch /opt/mesosphere/bin/wait_for_zookeeper.sh
chmod +x /opt/mesosphere/bin/wait_for_zookeeper.sh
cat <<EOF >>/opt/mesosphere/bin/wait_for_zookeeper.sh
#! /bin/sh
until /opt/mesosphere/bin/exhibitor_wait.py; do
  sleep 1
done
EOF

#touch /opt/mesosphere/bin/wait_for_file.sh
#chmod +x /opt/mesosphere/bin/wait_for_file.sh
#cat <<EOF >>/opt/mesosphere/bin/wait_for_file.sh
##! /bin/sh
#until [ -f "$1" ]; do
#  sleep 1
#done
#EOF



svc_rm_dep dcos-mesos-dns.service		dcos-mesos-master.service
svc_needs_zookeeper dcos-mesos-dns.service

svc_needs_zookeeper dcos-oauth.service

svc_needs dcos-cluster-id.service		dcos-exhibitor.service
svc_needs_zookeeper dcos-cluster-id.service

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

#svc_needs dcos.target				dcos-adminrouter.service

echo Launching

#rm /usr/bin/systemd-tty-ask-password-agent
#ln -s /bin/true /usr/bin/systemd-tty-ask-password-agent

systemctl start dcos-marathon.service
systemctl start dcos-adminrouter.service

systemctl -a | grep dcos

systemctl list-unit-files | grep dcos
exit


# keepalived is a monitor for VRRP
#
dcos-keepalived.service                enabled 

# Minuteman is the distributed firewall
#
dcos-minuteman.service                 enabled 

# dcos-signal seems to send data to mesophere.com
#
dcos-signal.service                    enabled 
dcos-signal.timer                      enabled 

