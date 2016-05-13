# Update all dcos unit files and add our environment file
#
find /opt/mesosphere/packages -type f -name dcos-*.service | uniq | while read file; do
  if grep -i '\[Install\]' ${file}; then
    sed -i -e '/[Install]/i EnvironmentFile=-${dcos_conf}' ${file}
  else
    echo EnvironmentFile=-${dcos_conf} >>${file}
  fi 
done

# Finally run pkgpanda and cleanup after its done
#
set -o allexport; . /opt/mesosphere/environment; set +o allexport
/opt/mesosphere/bin/pkgpanda setup --no-systemd || exit 1
