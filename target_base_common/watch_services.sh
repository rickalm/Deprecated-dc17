#! /bin/bash

watch -n 0.2 --diff 'systemctl -a | egrep \(rexray\|docker\|dcos\) | cut -b1-120 | sort -k3,3 -k4,4 -k1,1'
