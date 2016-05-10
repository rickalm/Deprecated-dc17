#! /bin/bash

# Load our Setup Functions
#
. /setup/service_functions.sh

# Run each setup script in order
#
rm /setup.loader 2>/dev/null; touch /setup.loader
find /setup/ -name *_setup.sh | sort | while read line; do
  echo echo Running $line >>/setup.loader
  echo . $line >>/setup.loader
done

. /setup.loader
rm /setup.loader
