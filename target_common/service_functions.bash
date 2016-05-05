find_file() {
  find /opt/mesosphere/packages -name $1
}

get_pkg_id() {
  basename $(find /opt/mesosphere/packages -maxdepth 1 -name $1*)
}

add_to_unit() {
  local key=$1
  local value=$2

  grep -qi "^${key}" ${service_filename} || sed -i -e "/\\[Unit\\]/a${key}=" ${service_filename}
  sed -i -e "/^${key}/I s~\$~ ${value}~" ${service_filename}
  sed -i -e 's~= ~=~' ${service_filename}
}

append_to_unit() {
  local key=$1
  local value=$2

  sed -i -e "/\\[Unit\\]/a${key}=${value}" ${service_filename}
}

svc(){
  service_filename=$(find_file $1)
  [ -z "${service_filename}" ] && echo Cant find $1 && exit 1
}

svc_sed() {
  local key=$1
  local value=$2

  sed -i -e "s~${key}~${value}~" ${service_filename}
}

svc_append() {
  echo $1 >>${service_filename}
}

svc_rm_dep() {
  sed -i -e "/$1/d" ${service_filename}
}

svc_add_prestart() {
  echo /\\[Service\\]/aExecStartPre=$@ >/tmp/$$.sed
  sed -i -f /tmp/$$.sed ${service_filename}
  rm /tmp/$$.sed
}

svc_needs_file() {
  svc_add_prestart "/usr/bin/test -f $1"
}

svc_must_ping() {
  svc_add_prestart "ping -w 10 -c 1 $1 || /bin/false"
}

svc_wants() {
  add_to_unit Wants $1
  add_to_unit After $1
}

svc_needs() {
  add_to_unit Requires $1
  add_to_unit After $1
}

svc_starts() {
  add_to_unit Requires $1
  add_to_unit Before $1
}

svc_cond_pathexists() {
  append_to_unit ConditionPathExists $1
}

svc_remove_old_deps() {
  svc_rm_dep exhibitor_wait
  svc_rm_dep 'ping .* ready.spartan'
  svc_rm_dep 'ping .* leader.mesos'
  svc_rm_dep 'ping .* marathon.mesos'
}

svc_waitfor_zookeeper() {
  svc_remove_old_deps 
  svc_add_prestart /opt/mesosphere/bin/wait_for_zookeeper.sh
}

svc_needs_zookeeper() {
  svc_waitfor_zookeeper
  svc_needs dcos-exhibitor.service
}

svc_waitfor_spartan() {
  svc_remove_old_deps
  svc_must_ping ready.spartan
}

svc_needs_spartan() {
  svc_waitfor_spartan
  svc_needs	dcos-spartan.service
}

svc_waitfor_leader() {
  svc_remove_old_deps
  svc_must_ping leader.mesos
}

svc_needs_leader() {
  svc_waitfor_leader
  svc_needs dcos-mesos-master.service
}

svc_waitfor_marathon() {
  svc_remove_old_deps
  svc_must_ping marathon.mesos
}

svc_needs_marathon() {
  svc_waitfor_marathon
  svc_needs dcos-marathon.service
}

svc_waitfor_clusterid() {
  svc_rm_dep var.lib.dcos.cluster-id
  svc_cond_pathexists /var/lib/dcos/cluster-id
}

svc_needs_clusterid() {
  svc_waitfor_clusterid
  svc_needs	dcos-cluster-id.service
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
