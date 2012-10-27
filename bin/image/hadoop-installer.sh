#!/usr/bin/env bash

# Import variables
bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
. "$bin"/hadoop-ec2-env.sh

HADOOP_VERSION="$1"

# Install Hadoop
echo "Installing Hadoop $HADOOP_VERSION."
cd /usr/local
wget -nv http://s3.amazonaws.com/myhadoop-images/hadoop-$HADOOP_VERSION.tar.gz
[ ! -f hadoop-$HADOOP_VERSION.tar.gz ] && wget -nv http://www.apache.org/dist/hadoop/core/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz
tar xzf hadoop-$HADOOP_VERSION.tar.gz
mv LongTermFairScheduler hadoop-1.0.3
rm -f hadoop-$HADOOP_VERSION.tar.gz

echo "/usr/local/hadoop-$HADOOP_VERSION *(rw,no_root_squash)" >> /etc/exports

service rpcbind start
service nfs start


