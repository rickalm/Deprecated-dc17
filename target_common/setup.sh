#! /bin/bash

# Load our Setup Functions
#
. /setup/service_functions.sh

# Run each setup script in order
#
rm /tmp/setup.loader 2>/dev/null; touch /tmp/setup.loader
find /setup/ -name *_setup.sh | sort | while read line; do
  echo echo Running $line >>/tmp/setup.loader
  echo . $line >>/tmp/setup.loader
done
. /tmp/setup.loader
rm /tmp/setup.loader
