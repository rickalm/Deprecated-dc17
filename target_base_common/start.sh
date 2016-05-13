#! /bin/bash


# If Argv1 is return_from_exec, then control was passed back to us, pass control to SystemD
#
[ "${1}" == "return_from_exec" ] && exec /usr/lib/systemd/systemd


# If Argv1 is a keyword, then take that action
# Used for debugging the container
#
[ "$1" == "sleep" ] && sleep 3600
[ "$1" == "bash" ] && exec bash


# Run each start script in order, we dont want to do this from within the while loop because
# that tends to be a child bash context, and we want to keep everything in pid 1
#
rm /start.loader 2>/dev/null
touch /start.loader
find /setup/ -name *_start.sh | sort | while read line; do
  echo echo Running. $line >>/start.loader
  echo . $line >>/start.loader
done

. /start.loader
rm /start.loader


# If the start_dind script is in place then call it telling it to return back to us
#
[ -f /start_dind.sh ] && exec /start_dind.sh $0 return_from_exec $@


# If there was no /start_dind.sh then pass control to SystemD
#
exec /usr/lib/systemd/systemd
