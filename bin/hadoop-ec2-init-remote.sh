#!/usr/bin/env bash

################################################################################
# Script that is run on each EC2 instance on boot. It is passed in the EC2 user
# data, so should not exceed 16K in size.
################################################################################

################################################################################
# Initialize variables
################################################################################

# Slaves are started after the master, and are told its address by sending a
# modified copy of this file which sets the MASTER_HOST variable. 
# A node  knows if it is the master or not by inspecting the security group
# name. If it is the master then it retrieves its address using instance data.

# Import variables
bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
. "$bin"/hadoop-ec2-env.sh

JAVA_VERSION=1.6.0_32
MASTER_HOST=%MASTER_HOST% # Interpolated before being sent to EC2 node
SECURITY_GROUPS=`wget -q -O - http://169.254.169.254/latest/meta-data/security-groups`
IS_MASTER=`echo $SECURITY_GROUPS | awk '{ a = match ($0, "-master$"); if (a) print "true"; else print "false"; }'`
if [ "$IS_MASTER" == "true" ]; then
 MASTER_HOST=`wget -q -O - http://169.254.169.254/latest/meta-data/local-hostname`
fi

################################################################################
# Hadoop configuration
# Modify this section to customize your Hadoop cluster.
################################################################################

cat > $HADOOP_HOME/conf/hadoop-env.sh <<EOF
export JAVA_HOME=/usr/local/jdk$JAVA_VERSION
export HADOOP_LOG_DIR=/mnt/hadoop/log
export HADOOP_HOME=$HADOOP_HOME
EOF

cat > $HADOOP_HOME/conf/core-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
	<property>
		<name>fs.default.name</name>
		<value>hdfs://%MASTER_HOST%:50001</value>
	</property>
</configuration>
EOF

cat > $HADOOP_HOME/conf/hdfs-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
	<property>
		<name>dfs.name.dir</name>
		<value>/mnt/hadoop/name</value>
	</property>
	<property>
		<name>dfs.data.dir</name>
		<value>/mnt/hadoop/data</value>
	</property>
</configuration>
EOF

cat > $HADOOP_HOME/conf/mapred-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
	<property>
		<name>mapred.job.tracker</name>
		<value>%MASTER_HOST%:50002</value>
	</property>
	<property>
		<name>mapred.tasktracker.map.tasks.maximum</name>
		<value>4</value>
	</property>
	<property>
		<name>mapred.tasktracker.reduce.tasks.maximum</name>
		<value>4</value>
	</property>
	<property>
		<name>mapred.acls.enabled</name>
		<value>false</value>
	</property>
	<property>
		<name>mapred.jobtracker.taskScheduler</name>
		<value>org.apache.hadoop.mapred.FairScheduler</value>
	</property>
	<property>
		<name>mapred.fairscheduler.preemption</name>
		<value>true</value>
	</property>
	<property>
		<name>mapred.fairscheduler.update.interval</name>
		<value>60000</value>
	</property>
	<property>
		<name>mapred.fairscheduler.creditupdateinterval</name>
		<value>60000</value>
	</property>
</configuration>
EOF

cat > $HADOOP_HOME/conf/fair-scheduler.xml <<EOF
<?xml version="1.0"?>
<allocations>
	<pool name="queue1">
		<minMaps>20</minMaps>
		<minReduces>20</minReduces>
		<maxMaps>80</maxMaps>
		<maxReduces>80</maxReduces>
		<minSharePreemptionTimeout>300</minSharePreemptionTimeout>
		<schedulingMode>fifo</schedulingMode>
	</pool>
	<pool name="queue2">
		<minMaps>20</minMaps>
		<minReduces>20</minReduces>
		<maxMaps>80</maxMaps>
		<maxReduces>80</maxReduces>
		<minSharePreemptionTimeout>300</minSharePreemptionTimeout>
		<schedulingMode>fifo</schedulingMode>
	</pool>
	<pool name="queue3">
		<minMaps>20</minMaps>
		<minReduces>20</minReduces>
		<maxMaps>80</maxMaps>
		<maxReduces>80</maxReduces>
		<minSharePreemptionTimeout>300</minSharePreemptionTimeout>
		<schedulingMode>fifo</schedulingMode>
	</pool>
	<pool name="queue4">
		<minMaps>20</minMaps>
		<minReduces>20</minReduces>
		<maxMaps>80</maxMaps>
		<maxReduces>80</maxReduces>
		<minSharePreemptionTimeout>300</minSharePreemptionTimeout>
		<schedulingMode>fifo</schedulingMode>
	</pool>
	<fairSharePreemptionTimeout>60</fairSharePreemptionTimeout>
	<defaultMinSharePreemptionTimeout>60</defaultMinSharePreemptionTimeout>
</allocations>
EOF

################################################################################
# Start services
################################################################################

echo 'Starting Service'

[ ! -f /etc/hosts ] &&  echo "127.0.0.1 localhost" > /etc/hosts

mkdir -p /mnt/hadoop/logs

# not set on boot
export USER="root"

if [ "$IS_MASTER" == "true" ]; then
  # MASTER

  # Hadoop
  # only format on first boot
  [ ! -e /mnt/hadoop/dfs ] && "$HADOOP_HOME"/bin/hadoop namenode -format

  "$HADOOP_HOME"/bin/start-all.sh
fi

# Run this script on next boot
rm -f /var/ec2/ec2-run-user-data.*

################################################################################
#Install workload generator
################################################################################

echo 'Downloading Workload Generator'

wget -nv 'https://s3.amazonaws.com/myhadoop-images/loadweaver.jar' --no-check-certificate
wget -nv 'https://s3.amazonaws.com/myhadoop-images/WorkloadGen-Conf.dtd' --no-check-certificate
wget -nv 'https://s3.amazonaws.com/myhadoop-images/config.xml' --no-check-certificate
wget -nv 'https://s3.amazonaws.com/myhadoop-images/exampleTrace.trace' --no-check-certificate
wget -nv 'https://s3.amazonaws.com/myhadoop-images/runloadweaver' --no-check-certificate
wget -nv 'https://s3.amazonaws.com/myhadoop-images/env_variables' --no-check-certificate
wget -nv 'https://s3.amazonaws.com/myhadoop-images/generateInputData.sh' --no-check-certificate
