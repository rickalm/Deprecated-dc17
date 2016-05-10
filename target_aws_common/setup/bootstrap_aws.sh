# Load the AWS CF Setup packages
#
BOOTSTRAP_URL=$(cat /etc/mesosphere/setup-flags/repository-url)
CONFIG_ID=45a8974c28d1f2a890628bdcff057261195b1aa2

/usr/bin/curl -fLo /tmp/t ${BOOTSTRAP_URL}/packages/dcos-config/dcos-config--setup_${CONFIG_ID}.tar.xz || exit 1
  tar -C /opt/mesosphere -Jxf /tmp/t
  rm /tmp/t

/usr/bin/curl -fLo /tmp/t ${BOOTSTRAP_URL}/packages/dcos-metadata/dcos-metadata--setup_${CONFIG_ID}.tar.xz || exit 1
  tar -C /opt/mesosphere -Jxf /tmp/t
  rm /tmp/t

# Define the default dcos-config packages for AWS
#
cat <<EOF >/etc/mesosphere/setup-flags/cluster-packages.json
[
  "dcos-config--setup_${CONFIG_ID}",
  "dcos-metadata--setup_${CONFIG_ID}"
]
EOF
