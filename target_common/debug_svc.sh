#!/bin/bash
rm /tmp/$$.env 2>/dev/null
touch /tmp/$$?env

systemctl cat $1.service | grep EnvironmentFile= | cut -d= -f2 | sed -e 's/^-//' | while read file; do
  echo Loading ${file}
  [ -f "${file}" ] && cat ${file} >>/tmp/$$.env
done

systemctl cat $1.service | grep Environment= | cut -d= -f2- | while read var; do
  echo Eval ${var}
  eval ${var} >>/tmp/$$.env
done

set -a; . /tmp/$$.env; set +a
env

systemctl cat $1.service | grep ExecStartPre= | cut -d= -f2 | sed -e 's/^-//' | while read cmd; do
  echo PreExec ${cmd}
  [ -f "$(echo ${cmd} | cut -d\   -f1)" ] && ${cmd}; echo $?
done

systemctl cat $1.service | grep ExecStart= | cut -d= -f2 | sed -e 's/^-//' | while read cmd; do
  echo Running ${cmd}
  [ -f "$(echo ${cmd} | cut -d\   -f1)" ] && ${cmd}; echo $?
done
