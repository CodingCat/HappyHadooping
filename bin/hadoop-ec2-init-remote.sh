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

JAVA_VERSION=1.6.0_32
MASTER_HOST=%MASTER_HOST% # Interpolated before being sent to EC2 node
SECURITY_GROUPS=`wget -q -O - http://169.254.169.254/latest/meta-data/security-groups`
IS_MASTER=`echo $SECURITY_GROUPS | awk '{ a = match ($0, "-master$"); if (a) print "true"; else print "false"; }'`
if [ "$IS_MASTER" == "true" ]; then
 MASTER_HOST=`wget -q -O - http://169.254.169.254/latest/meta-data/local-hostname`
fi

HADOOP_HOME=`ls -d /usr/local/hadoop-*`

################################################################################
# Hadoop configuration
# Modify this section to customize your Hadoop cluster.
################################################################################

cat > $HADOOP_HOME/conf/hadoop-env.sh <<EOF
export JAVA_HOME=/usr/local/jdk$JAVA_VERSION
export HADOOP_LOG_DIR=/mnt/hadoop/log
EOF

cat > $HADOOP_HOME/conf/core-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
	<property>
		<name>fs.default.name</name>
		<value>hdfs://$MASTER_HOST:50001</value>
	</property>
</configuration>
EOF

cat > $HADOOP_HOME/conf/hdfs-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
	<property>
		<name>dfs.name.dir</name>
		<value>/mnt/hadoop/namenode/</value>
	</property>
	<property>
		<name>dfs.data.dir</name>
		<value>/mnt/hadoop/datanode/</value>
	</property>
</configuration>
EOF

cat > $HADOOP_HOME/conf/mapred-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
	<property>
		<name>mapred.job.tracker</name>
		<value>hdfs://$MASTER_HOST:50002</value>
	</property>
	<property>
		<name>mapred.system.dir</name>
		<value>/mnt/hadoop/mapred/system</value>
	</property>
	<property>
		<name>mapred.local.dir</name>
		<value>/mnt/hadoop/mapred/map</value>
	</property>
	<property>
		<name>mapred.queue.names</name>
		<value>default</value>
	</property>
	<property>
		<name>mapred.acls.enabled</name>
		<value>false</value>
	</property>
</configuration>

EOF

# Configure Hadoop for Ganglia
# overwrite hadoop-metrics.properties
cat > $HADOOP_HOME/conf/hadoop-metrics.properties <<EOF

# Ganglia
# we push to the master gmond so hostnames show up properly
dfs.class=org.apache.hadoop.metrics.ganglia.GangliaContext
dfs.period=10
dfs.servers=$MASTER_HOST:8649

mapred.class=org.apache.hadoop.metrics.ganglia.GangliaContext
mapred.period=10
mapred.servers=$MASTER_HOST:8649

jvm.class=org.apache.hadoop.metrics.ganglia.GangliaContext
jvm.period=10
jvm.servers=$MASTER_HOST:8649
EOF

################################################################################
# Start services
################################################################################

[ ! -f /etc/hosts ] &&  echo "127.0.0.1 localhost" > /etc/hosts

mkdir -p /mnt/hadoop/logs

# not set on boot
export USER="root"

if [ "$IS_MASTER" == "true" ]; then
  # MASTER
  # Prep Ganglia
  sed -i -e "s|\( *mcast_join *=.*\)|#\1|" \
         -e "s|\( *bind *=.*\)|#\1|" \
         -e "s|\( *mute *=.*\)|  mute = yes|" \
         -e "s|\( *location *=.*\)|  location = \"master-node\"|" \
         /etc/gmond.conf
  mkdir -p /mnt/ganglia/rrds
  chown -R ganglia:ganglia /mnt/ganglia/rrds
  rm -rf /var/lib/ganglia; cd /var/lib; ln -s /mnt/ganglia ganglia; cd
  service gmond start
  service gmetad start
  apachectl start

  # Hadoop
  # only format on first boot
  [ ! -e /mnt/hadoop/dfs ] && "$HADOOP_HOME"/bin/hadoop namenode -format

  "$HADOOP_HOME"/bin/hadoop-daemon.sh start namenode
  "$HADOOP_HOME"/bin/hadoop-daemon.sh start jobtracker
else
  # SLAVE
  # Prep Ganglia
  sed -i -e "s|\( *mcast_join *=.*\)|#\1|" \
         -e "s|\( *bind *=.*\)|#\1|" \
         -e "s|\(udp_send_channel {\)|\1\n  host=$MASTER_HOST|" \
         /etc/gmond.conf
  service gmond start

  # Hadoop
  "$HADOOP_HOME"/bin/hadoop-daemon.sh start datanode
  "$HADOOP_HOME"/bin/hadoop-daemon.sh start tasktracker
fi

# Run this script on next boot
rm -f /var/ec2/ec2-run-user-data.*
