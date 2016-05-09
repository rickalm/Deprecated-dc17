#!/bin/bash
rm /tmp/$$.env 2>/dev/null
touch /tmp/$$?env

file=$(find /etc/systemd -name $1.service -printf '%l\n' | uniq)

cat ${file} | grep EnvironmentFile= | cut -d= -f2 | sed -e 's/^-//' | while read file; do
  echo Loading ${file}
  [ -f "${file}" ] && cat ${file} >>/tmp/$$.env
done

cat ${file} | grep Environment= | cut -d= -f2- | while read var; do
  echo Eval ${var}
  eval ${var} >>/tmp/$$.env
done

set -o allexport; . /tmp/$$.env; set +o allexport
env

cat ${file} | grep ExecStartPre= | cut -d= -f2 | sed -e 's/^-//' | while read cmd; do
  echo PreExec ${cmd}
  [ -f "$(echo ${cmd} | cut -d\   -f1)" ] && ${cmd}; echo $?
done

cat ${file} | grep ExecStart= | cut -d= -f2 | sed -e 's/^-//' | while read cmd; do
  echo Running ${cmd}
  [ -f "$(echo ${cmd} | cut -d\   -f1)" ] && ${cmd}; echo $?
done
