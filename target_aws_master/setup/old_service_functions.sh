#! /bin/bash

echo Using Target_AWS_Master service functions

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

dcos_config_dir=$(find /etc/mesosphere/setup-packages -name *docker--setup*)

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
