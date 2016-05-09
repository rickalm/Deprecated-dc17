#! /bin/sh

# If AWS_ZONE or AWS_REGION arnt defined go figure it out
#
AWS_ZONE=${AWS_ZONE:-$(curl -sS http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/[a-z]$//')}
AWS_REGION=${AWS_REGION:-$(echo ${AWS_ZONE} | sed -e 's/[a-z]$//')}

# If DCOS_ vars arnt defined, use the discovered AWS_ params
#
DCOS_DATACENTER=${DCOS_DATACENTER:-${AWS_ZONE}}
DCOS_REGION=${DCOS_REGION:-${AWS_REGION}}
