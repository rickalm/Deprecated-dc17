#! /bin/bash

# In order to keep systemd as PID 1, we keep passing the exec handle
# this prevents a loop
#
if [ "${1}" != "return_from_dind" ]; then
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

  # If the start_dind script is in place then call it telling it to return back to us
  #
  [ -f /start_dind.sh ] && exec /start_dind.sh /start.sh return_from_dind $@

else
  # Drop the flag from the args
  #
  shift

fi

# Pass control to SystemD/Init
#
[ -f "/usr/lib/systemd/systemd" ] && exec /usr/lib/systemd/systemd
exec /usr/sbin/init
