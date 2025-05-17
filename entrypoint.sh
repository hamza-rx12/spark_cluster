#!/bin/bash

SPARK_WORKLOAD=$1

echo "SPARK_WORKLOAD: $SPARK_WORKLOAD"

if [ "$SPARK_WORKLOAD" == "master" ];
then
  start-master.sh -p 7077 & \
  jupyter lab --ip=0.0.0.0 \
              --port=8888 \
              --allow-root \
              --no-browser \
              --NotebookApp.token='' \
              --NotebookApp.password='' \
              --NotebookApp.allow_origin='*' \
              --NotebookApp.allow_remote_access=True
elif [ "$SPARK_WORKLOAD" == "worker" ];
then
  start-worker.sh spark://spark-master:7077
elif [ "$SPARK_WORKLOAD" == "history" ]
then
  start-history-server.sh
fi
