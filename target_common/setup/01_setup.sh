
# Install DCOS Bootstrap Repo
#
echo Bootstraping

BOOTSTRAP_URL=https://downloads.mesosphere.com/dcos/EarlyAccess
BOOTSTRAP_ID=a31ed4c418a9d0d55d5304171e1ac2fce4ddc797
CONFIG_ID=45a8974c28d1f2a890628bdcff057261195b1aa2

mkdir -p /opt/mesosphere
[ ! -f /bootstrap.tar.xz ] && /usr/bin/curl -Lo /bootstrap.tar.xz ${BOOTSTRAP_URL}/bootstrap/${BOOTSTRAP_ID}.bootstrap.tar.xz
tar -C /opt/mesosphere -Jxf /bootstrap.tar.xz
rm /bootstrap.tar.xz

echo Bootstrap done

# Save the Bootstrap params where DCOS expects them
#
mkdir -p /etc/mesosphere/setup-flags
echo BOOTSTRAP_ID=${BOOTSTRAP_ID} >/etc/mesosphere/setup-flags/bootstrap-id
echo ${BOOTSTRAP_URL} >/etc/mesosphere/setup-flags/repository-url

# Fixup pkgpython so it doesnt cause issues with renaming a directory
#
sed -i -e 's/os.rename(active, old_path)/os.system("mv "+active+" "+old_path)/' \
  /opt/mesosphere/lib/python3.4/site-packages/pkgpanda/__init__.py

sed -i -e 's/os.rename(active, old_path)/os.system("mv "+active+" "+old_path)/' \
  /opt/mesosphere/active/dcos-image/lib/python3.4/site-packages/pkgpanda/__init__.py

# Define the default dcos-config packages for AWS
#
cat <<EOF >/etc/mesosphere/setup-flags/cluster-packages.json
[
  "dcos-config--setup_${CONFIG_ID}",
  "dcos-metadata--setup_${CONFIG_ID}"
]
EOF

# Make the roles directory
#
mkdir -p /etc/mesosphere/roles

# Setup JournalD for DCOS
#
mkdir -p /etc/systemd/journald.conf.d
echo '[Journal]' >>/etc/systemd/journald.conf.d/dcos.conf
echo 'MaxLevelConsole=warning' >>/etc/systemd/journald.conf.d/dcos.conf

# Link DCOS environment to Login profile
#
mkdir -p /etc/profile.d
/usr/bin/ln -sf /opt/mesosphere/environment.export /etc/profile.d/dcos.sh

# Create group nogroup incase it doesnt exist
#
groupadd nogroup 2>/dev/null

# Symlink directories Mesos uses to /data
#
ln -sf /data/var/log/mesos /var/log/mesos
ln -sf /data/var/log/mesosphere /var/log/mesosphere
ln -sf /data/var/lib/mesos /var/lib/mesos
ln -sf /data/var/lib/mesosphere /var/lib/mesosphere
ln -sf /data/var/lib/dcos /var/lib/dcos
ln -sf /data/var/lib/zookeeper /var/lib/zookeeper
ln -sf /data/var/lib/cosmos /var/lib/cosmos
