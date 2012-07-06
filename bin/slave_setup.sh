# Import variables
bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
. "$bin"/hadoop-ec2-env.sh

NFS_HOST=`ec2-describe-instances | grep 'running' | head -1 | awk '{print $4}'`
INSTANCE_NUM=`ec2-describe-instances | grep 'running' | wc -l`
SLAVE_NUM=`expr $INSTANCE_NUM - 2`
NUM=1

echo 'setup slave nodes';

while true; do 
	CURRENT_SLAVE_IP=`sed -n "$NUM,$NUM"p slaves`
	echo $CURRENT_SLAVE_IP
	if [ $NUM -gt $SLAVE_NUM ]; then
		break;
	fi

	ssh $SSH_OPTS "root@$CURRENT_SLAVE_IP" 'service rpcbind start';
	ssh $SSH_OPTS "root@$CURRENT_SLAVE_IP" 'service nfs start';
	ssh $SSH_OPTS "root@$CURRENT_SLAVE_IP" "mkdir /usr/local/hadoop-$HADOOP_VERSION"
	ssh $SSH_OPTS "root@$CURRENT_SLAVE_IP" "mount -v -t nfs $NFS_HOST:/usr/local/hadoop-$HADOOP_VERSION /usr/local/hadoop-$HADOOP_VERSION"
	NUM=`expr $NUM + 1`;
done

#cat slaves | while read line;do CURRENT_SLAVE_IP=`echo $line`;echo "setup slave node $CURRENT_SLAVE_IP";ssh $SSH_OPTS root@$CURRENT_SLAVE_IP 'service rpcbind start' ; done
#start rpcbind and nfs
#ssh $SSH_OPTS "root@$CURRENT_SLAVE_IP" 'service rpcbind start';
#ssh $SSH_OPTS "root@$CURRENT_SLAVE_IP" 'service nfs start';
#echo $line;
#done
	#ssh $SSH_OPTS "root@$CURRENT_SLAVE_IP" "mkdir /usr/local/hadoop-$HADOOP_VERSION"
	#ssh $SSH_OPTS "root@$CURRENT_SLAVE_IP" "umount /usr/local/hadoop-$HADOOP_VERSION"
	#ssh $SSH_OPTS "root@$CURRENT_SLAVE_IP" "mount -v -f -t nfs $NFS_HOST:/usr/local/hadoop-$HADOOP_VERSION /usr/local/hadoop-$HADOOP_VERSION"
