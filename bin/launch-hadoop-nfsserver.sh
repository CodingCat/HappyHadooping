#!/usr/bin/env bash

bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
. "$bin"/hadoop-ec2-env.sh

if [ -z $AWS_ACCOUNT_ID ]; then
  echo "Please set AWS_ACCOUNT_ID in $bin/hadoop-ec2-env.sh."
  exit -1
fi

if [ -z $1 ]; then
  echo "Cluster name required!"
  exit -1
fi

if [ -z $2 ]; then
  echo "Hadoop version required!"
  exit -1
fi

CLUSTER_NAME=$1


ec2-describe-group | egrep "[[:space:]]$CLUSTER_NAME[[:space:]]" > /dev/null
if [ ! $? -eq 0 ]; then
  echo "Creating group $CLUSTER_NAME"
  ec2-add-group $CLUSTER_NAME -d "Group for Hadoop Cluster."
  ec2-authorize $CLUSTER_NAME -u $AWS_ACCOUNT_ID
  ec2-authorize $CLUSTER_NAME -p 22    # ssh
fi

# Finding Hadoop image
AMI_IMAGE=`ec2-describe-images -a | grep $S3_BUCKET | grep $HADOOP_VERSION | grep $ARCH | grep available | awk '{print $2}'`

# Start a nfs-server 
echo "Starting nfs-server with AMI $AMI_IMAGE"
INSTANCE=`ec2-run-instances $AMI_IMAGE -n 1 -k $KEY_NAME -g $CLUSTER_NAME -f "$bin"/$USER_DATA_FILE | grep INSTANCE | awk '{print $2}'`
echo "Waiting for instance $INSTANCE to start"
while true; do
  printf "."
  # get public dns
  NFS_HOST=`ec2-describe-instances $INSTANCE | grep running | awk '{print $4}'`
  if [ ! -z $NFS_HOST ]; then
    echo "Started as $NFS_HOST"
    break;
  fi
  sleep 1
done

#echo $SSH_OPTS
#wait for ssh port ready

while true; do 
	REPLY=`SSH $SSH_OPTS "root@$NFS_HOST" 'echo "hello"'`
	if [ ! -z $REPLY ]; then
		break;
	fi
#	sleep 5
done

scp $SSH_OPTS "$bin"/image/ec2-run-user-data "root@$NFS_HOST:/etc/init.d"
scp $SSH_OPTS $EC2_KEYDIR/pk*.pem "root@$NFS_HOST:/mnt"
scp $SSH_OPTS $EC2_KEYDIR/cert*.pem "root@$NFS_HOST:/mnt"
scp $SSH_OPTS hadoop-ec2-env.sh "root@$NFS_HOST:/mnt"
scp $SSH_OPTS image/hadoop-installer.sh "root@$NFS_HOST:/mnt"

# Connect to it
ssh $SSH_OPTS "root@$NFS_HOST" "/mnt/hadoop-installer.sh $2"

NFS_PRIVATE_IP=`ec2-describe-instances $INSTANCE | grep running | awk '{print \$16}'`
