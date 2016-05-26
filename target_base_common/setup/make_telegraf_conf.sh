#! /bin/bash

get_section() {
  cp $1 /tmp/$$.tmp
  local section=$2

  # Find where our section starts and delete everything before that
  #
  start_ln=$( grep -n "^\\[*${section}\\]*" /tmp/$$.tmp | cut -d: -f1 )
  [ "0${start_ln}" -gt 1 ] && sed -i -e "1,$[$start_ln - 1]d" /tmp/$$.tmp


  # make sure there is a section following the stripped file, then delete everything after the section we grabbed
  #
  echo '[[end]]' >>/tmp/$$.tmp
  end_ln=$( grep -n "^\\[" /tmp/$$.tmp | sed -ne '2p' | cut -d: -f1 )
  [ "0${end_ln}" -gt 0 ] && sed -i -e "$end_ln,\$d" /tmp/$$.tmp

  # Output the results and clean up
  #
  sed -e 's/#.*$//' /tmp/$$.tmp
  rm /tmp/$$.tmp
}

usage() {
cat <<EOF
$0 - Create telegraf.conf for Docker containers

This strips the telegraf.conf file passed into the container 
uses the existing global_tags and agent sections plus any outputs.* sections
then appends the passed in config file

usage: $0 [options] output.filename
  * output.filename: default /etc/telegraf/telegraf.conf

  * -i source.filename: Which file to use as the seed for global and outputs section
       if not specified, will look at mounts passed into container and use any files
       mounted as */telegraf.conf

  * -a another.filename: a file to append to the constructed file which will be included
       onto the tail of the output

  * --no-default: rejects the inclusion of the default inputs this script normally uses
       The default includes: cpu, netstat and docker

  Examples:
    Simply configure this telegraf to monitor docker
      $0 /etc/telegraf/telegraf.conf

    Configure telegraf to only monitor Zookeeper and skip the defaults
      $0 --no-default -a zookeeper.conf

EOF

exit 1
}

append_defaults() {  
[ -n "${no_def}" ] && return

cat <<EOF
[[inputs.diskio]]
  devices = ["xvda", "xvdb", "xvdc", "xvdd", "xvde", "xvdf", "xvdg", "xvdh", "xvdi", "xvdj", "xvdk", "xvdl", "xvdm", "xvdn", "xvdo", "xvdp", "xvdq", "xvdr", "xvds", "xvdt", "xvdu", "xvdv", "xvdw", "xvdx", "xvdy", "xvdz"]

# Read TCP metrics such as established, time wait and sockets counts.
#
[[inputs.netstat]]

# Read metrics about docker containers
#
[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"
  container_names = []
  timeout = "5s"

EOF
}

# Process any command line options
#
while [ -n "$1" ]; do
  case $1 in
    -i) source=$2; shift
        ;;

    # If a file was specified and doesnt exist bail out otherwise add to list
    #
    -a) [ ! -f "$2" ] && echo "ERROR: Could not find file specified $2" && usage
        append_list="${append_list} $2"; shift
        ;;

    --no-default) no_def=1
        ;;

  esac
  shift
done

# Define the output if not specified
#
output=${1:-/etc/telegraf/telegraf.conf}

# Search for source file as follows (if not specified in options)
# - Search mount table for a telegraf.conf
# - is there a telegraf.conf in the PWD
# Otherwise, complain and die
#
source=${source:-$(mount | sed -e 's/^.* on //' -e 's/ type .*$//' | grep telegraf.conf)}
[ -f ./telegraf.conf ] && source=${source:-./telegraf.conf}
[ -z "${source}" ] && usage


# Ok, now go put it all together
#
# Grab global_tags, agent and all of the current output sections
#
rm /tmp/telegraf.$$.conf
outputs="global_tags agent $(grep '^\[\[outputs\.' $source | tr -d '[]')"
for section in $outputs; do
  get_section $source $section >>/tmp/telegraf.$$.conf
done

# Append the defaults unless told not to
#
[ -z "${no_def}" ] && append_defaults >>/tmp/telegraf.$$.conf

# Now append the files specified by the user on the command line
#
[ -n "${append_list}" ] && cat ${append_list} >>/tmp/telegraf.$$.conf

# Lastly, put our file into place
#
install -D /tmp/telegraf.$$.conf /etc/telegraf/telegraf.conf
