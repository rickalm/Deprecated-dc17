#! /bin/sh

# If AWS_ZONE or AWS_REGION arnt defined go figure it out
#
export AWS_ZONE=${AWS_ZONE:-$(curl -sS http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/[a-z]$//')}
export AWS_REGION=${AWS_REGION:-$(echo ${AWS_ZONE} | sed -e 's/[a-z]$//')}

# If DCOS_ vars arnt defined, use the discovered AWS_ params
#
export DCOS_DATACENTER=${DCOS_DATACENTER:-${AWS_ZONE}}
export DCOS_REGION=${DCOS_REGION:-${AWS_REGION}}
