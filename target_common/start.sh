#! /bin/bash

[ "$1" == "sleep" ] && sleep 3600
[ "$1" == "bash" ] && exec bash

# Run each start script in order
#
rm /start.loader 2>/dev/null; touch /start.loader
find /setup/ -name *_start.sh | sort | while read line; do
  echo echo Running. $line >>/start.loader
  echo . $line >>/start.loader
done

. /start.loader
rm /start.loader

# Pass control to SystemD
#
exec /usr/sbin/init
