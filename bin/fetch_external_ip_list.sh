#!/bin/sh

#Get the Instance List with IP Address

#Written By Nan Zhu
#2011/10/30

# Import variables
bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
. "$bin"/hadoop-ec2-env.sh

#dump instances
HOSTS=`ec2-describe-instances | grep INSTANCE | grep running | awk '{print \$15}'`;
IFS=' \n'
HOSTS_ADDR=($HOSTS)

echo $HOSTS_ADDR > slaves.tmp
sed -e '1d' slaves.tmp > slaves
rm slaves.tmp
