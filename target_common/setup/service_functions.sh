echo Using Common Service_Functions

find_file() {
  find -L /opt/mesosphere/active -name $1
}

#get_pkg_id() {
#  basename $(find /opt/mesosphere/packages -maxdepth 1 -name $1*)
#}

add_to_unit() {
  local key=$1
  local value=$2

  grep -qi "^${key}" ${unit_filename} || sed -i -e "/\\[Unit\\]/a${key}=" ${unit_filename}
  sed -i -e "/^${key}/I s~\$~ ${value}~" ${unit_filename}
  sed -i -e 's~= ~=~' ${unit_filename}
}

append_to_unit() {
  local key=$1
  local value=$2

  sed -i -e "/\\[Unit\\]/a${key}=${value}" ${unit_filename}
}

svc(){
  unit_filename=$(find_file $1)
  [ -z "${unit_filename}" ] && echo Cant find $1 && ls -la /opt/mesosphere/active && exit 1
  echo Updating $1
}

svc_sed() {
  local key=$1
  local value=$2

  sed -i -e "s~${key}~${value}~" ${unit_filename}
}

svc_append() {
  echo $1 >>${unit_filename}
}

svc_rm_line() {
  sed -i -e "/$1/d" ${unit_filename}
}

svc_add_prestart() {
  echo /\\[Service\\]/aExecStartPre=$@ >/tmp/$$.sed
  sed -i -f /tmp/$$.sed ${unit_filename}
  rm /tmp/$$.sed
}

svc_needs_file() {
  svc_add_prestart "/usr/bin/test -f $1"
}

svc_must_ping() {
  svc_add_prestart /bin/ping -w 30 -c 1 $1
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
  svc_rm_line exhibitor_wait
  svc_rm_line 'ping.+ready.spartan'
  svc_rm_line 'ping.+leader.mesos'
  svc_rm_line 'ping.+marathon.mesos'
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
  svc_rm_line var.lib.dcos.cluster-id
  svc_cond_pathexists /var/lib/dcos/cluster-id
}

svc_needs_clusterid() {
  svc_waitfor_clusterid
  svc_needs	dcos-cluster-id.service
}

#touch ${dcos_dir}/bin/wait_till_ping.sh
#chmod +x ${dcos_dir}/bin/wait_till_ping.sh
#cat <<EOF >>${dcos_dir}/bin/wait_till_ping.sh
##! /bin/sh
#until ping -c 1 \$1 || /bin/false; do
#  sleep 1
#done
#EOF
#
#touch ${dcos_dir}/bin/wait_for_zookeeper.sh
#chmod +x ${dcos_dir}/bin/wait_for_zookeeper.sh
#cat <<EOF >>${dcos_dir}/bin/wait_for_zookeeper.sh
##! /bin/sh
#until ${dcos_dir}/exhibitor_wait.py; do
#  sleep 1
#done
#EOF
