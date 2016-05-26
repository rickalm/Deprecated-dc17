# Absorb the passed telegraf config file then launch the service
#
bash  /setup/make_telegraf_conf.sh

[ -f /etc/telegraf/telegraf.conf ] && systemctl enable /usr/lib/telegraf/scripts/telegraf.service
systemctl start telegraf

