#! /bin/bash

[ "$1" == "sleep" ] && sleep 3600
[ "$1" == "bash" ] && exec bash

# Run each start script in order
#
rm /tmp/start.loader 2>/dev/null; touch /tmp/start.loader
find /setup/ -name *_start.sh | sort | while read line; do
  echo echo Running. $line >>/tmp/start.loader
  echo . $line >>/tmp/start.loader
done

. /tmp/start.loader
rm /tmp/start.loader

# Pass control to SystemD
#
exec /usr/sbin/init
