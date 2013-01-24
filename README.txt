1. launch a new cluster

./launch-hadoop-cluster cluster-name number_of_machines

e.g.

./launch-hadoop-cluster test-cluster 30 (suggest to use test-cluster as the cluster name, once met some problem with other names)

will create a cluster with 32 machines, 30 worker nodes, 1 nfs server, 1 master node



2. login to the cluster

./hadoop-ec2 login test-cluster

this command will lead you to the master node of the cluster

3. setup hadoop cluster

go to the directory, /usr/local/hadoop-1.0.3

3.1 setup hadoop cluster

$ vi conf/mapred-site.xml

max map/reduce slots per machine: mapred.tasktracker.map.tasks.maximum/mapred.tasktracker.reduce.tasks.maxium

scheduler:mapred.jobtracker.taskScheduler

default FIFO scheduler: org.apache.hadoop.mapred.JobQueueTaskScheduler
Fair scheduler: org.apache.hadoop.mapred.FairScheduler
CreditScheduler: org.apache.hadoop.mapred.CreditScheduler

NOTICE:

before you change the scheduler setup you have to do following things:

a. stop the hadoop cluster

$ bin/stop-mapred.sh

(after you finish the setup, bin/start-mapred.sh, will restart the cluster)

b. fairscheduler.jar and creditscheduler.jar exclusively exist under lib/ directory, so if you run fair scheduler, please delete creditscheduler.jar first, the same for the reverse case

and jar can be downloaded via s3.amazonaws.com/myhadoop-images/hadoop-creditscheduler-1.0.3.jar, or s3.amazonaws.com/myhadoop-images/hadoop-fairscheduler-1.0.3.jar

3.2 setup the credit/fair scheduler 

$ vi conf/credit-scheduler.xml (or fair-scheduler.xml)

PS:set MaxMap and MaxReduce to a very large number, e.g. 10000, because hadoop doesn't allow demand more than the total capacity


3.3 setup the Workload generator

go to the home directory

3.3.1 set up HADOOP_HOME in env_variables, (/usr/local/hadoop-1.0.3)

3.3.2 generate random data, setup input size in generateInputData.sh, COMPRESSED_DATA_BYTES, and UNCOMPRESSED_DATA_BYTES, (in bytes, NUM_MAPS indicates how many parallel tasks will be used to generate data, you can set it as the capacity of your cluster)

NOTICE: before you do this, set the schedule to JobQueueTaskScheduler

$ sh generateinput.sh

3.3.3 when you run Fair and Credit scheduler, ensure workloadgen.system.multiqueue is set to true

3.3.4 trace

$ vi example.trace

NOTICE, list the jobs in the order of submit time, didn't handle disorder case in implementation

some known data:

websort, 50G input data, 100 pieces, 

reduce tasks number is recommmeded to be 0.9 * map tasks num

small jobs, 9 map tasks, 8 reduce tasks
medium jobs, 90 map tasks, 81 reduce tasks

3.3.5 start the workload gen

$ sh runloadweaver


4. stop the amazon ec2 instances

$ ./terminate-cluster test-cluster
