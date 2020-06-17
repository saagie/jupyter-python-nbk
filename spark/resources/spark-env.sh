#!/usr/bin/env bash
shuffle=false
#if [[ $APACHE_SPARK_VERSION == "2.1.0" ]]; then
#    shuffle=true
#elif [[ $SPARK_VERSION == "2.1.0" ]]; then
#    shuffle=true
#fi

if [ -z "$SPARK_VERSION" ]; then
    export SPARK_VERSION=$APACHE_SPARK_VERSION
fi

export HADOOP_CONF_DIR=/etc/hadoop/conf/

#this a hack
#export SPARK_CONF_DIR=$(mktemp -d)
export SPARK_CONF_DIR=$SPARK_HOME/conf
#cp /tmp/spark-defaults.conf $SPARK_CONF_DIR/spark-defaults.conf
cp $SPARK_CONF_DIR/spark-defaults.conf.orig $SPARK_CONF_DIR/spark-defaults.conf
echo "spark.ui.port     $PORT0" >> $SPARK_CONF_DIR/spark-defaults.conf

if [ -z "$PYTHON_VERSION" ]; then
   echo "spark.mesos.executor.docker.image     saagie/spark:java-$JAVA_VERSION-$SPARK_VERSION-1.3.1-centos" >> $SPARK_CONF_DIR/spark-defaults.conf
else
   echo "spark.mesos.executor.docker.image     saagie/spark:python-$PYTHON_VERSION-$SPARK_VERSION-1.3.1-centos" >> $SPARK_CONF_DIR/spark-defaults.conf
fi

echo "spark.shuffle.service.enabled               $shuffle" >> $SPARK_CONF_DIR/spark-defaults.conf
echo "spark.dynamicAllocation.enabled             $shuffle" >> $SPARK_CONF_DIR/spark-defaults.conf

# hack for notebook
if [ -z "$PORT1" ]; then
  PORT1=$PORT0
fi

echo "spark.driver.port $PORT1" >> $SPARK_CONF_DIR/spark-defaults.conf
cp $SPARK_CONF_DIR/spark-defaults.conf $SPARK_CONF_DIR/spark-defaults.conf.new1

echo "spark.kubernetes.namespace $(cat /etc/hostname)" >> $SPARK_CONF_DIR/spark-defaults.conf

export PYSPARK_PYTHON=/opt/conda/envs/py36/bin/python


cp $SPARK_CONF_DIR/spark-defaults.conf $SPARK_CONF_DIR/spark-defaults.conf.new2
