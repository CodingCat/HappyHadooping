HADOOP_VERSION=1.0.0
HADOOP_HOME=/Users/zhunan/codes/LongTermFairScheduler

tar --exclude=$HADOOP_HOME/src/ --exclude=$HADOOP_HOME/.git/ --exclude=$HADOOP_HOME/docs/ -cvf $HADOOP_HOME/../hadoop-$HADOOP_VERSION.tar.gz $HADOOP_HOME 
