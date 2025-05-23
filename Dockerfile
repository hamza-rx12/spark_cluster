FROM python:3.10-bullseye as spark-base

RUN apt-get update &&\
	apt-get install -y --no-install-recommends \
	sudo \
	curl \
	vim \
	unzip \
	rsync \
	openjdk-11-jdk \
	build-essential \
	software-properties-common \
	ssh \
	apt-transport-https\
	gnupg 

RUN curl -fL "https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz" | gzip -d > cs

RUN apt-get clean && \
    	rm -rf /var/lib/apt/lists/* &&\
	curl -Lo coursier https://git.io/coursier-cli &&\
	chmod +x coursier &&\
	./coursier launch almond -- --install &&\
	rm -f coursier 
	

## Download spark and hadoop dependencies and install

# ENV variables
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
ENV HADOOP_HOME=${HADOOP_HOME:-"/opt/hadoop"}
ENV SPARK_VERSION=3.5.5
ENV PYTHONPATH=$SPARK_HOME/python/:$PYTHONPATH

ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"
ENV SPARK_HOME="/opt/spark"
ENV SPARK_MASTER="spark://spark-master:7077"
ENV SPARK_MASTER_HOST spark-master
ENV SPARK_MASTER_PORT 7077
ENV PYSPARK_PYTHON python3

# Add iceberg spark runtime jar to IJava classpath
ENV IJAVA_CLASSPATH=/opt/spark/jars/*

RUN mkdir -p ${HADOOP_HOME} && mkdir -p ${SPARK_HOME}
WORKDIR ${SPARK_HOME}

# Download spark
RUN mkdir -p ${SPARK_HOME} \
    && curl https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz -o spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && tar xzvf spark-${SPARK_VERSION}-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
    && rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz


FROM spark-base as pyspark

# Install python deps
COPY requirements.txt .
RUN pip3 install -r requirements.txt

COPY conf/spark-defaults.conf "$SPARK_HOME/conf"

RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/*


FROM pyspark

# Download iceberg spark runtime
RUN curl https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.4_2.12/1.4.3/iceberg-spark-runtime-3.4_2.12-1.4.3.jar -Lo /opt/spark/jars/iceberg-spark-runtime-3.4_2.12-1.4.3.jar

# Download delta jars
RUN curl https://repo1.maven.org/maven2/io/delta/delta-core_2.12/2.4.0/delta-core_2.12-2.4.0.jar -Lo /opt/spark/jars/delta-core_2.12-2.4.0.jar
RUN curl https://repo1.maven.org/maven2/io/delta/delta-spark_2.12/3.2.0/delta-spark_2.12-3.2.0.jar -Lo /opt/spark/jars/delta-spark_2.12-3.2.0.jar
RUN curl https://repo1.maven.org/maven2/io/delta/delta-storage/3.2.0/delta-storage-3.2.0.jar -Lo /opt/spark/jars/delta-storage-3.2.0.jar

# Download hudi jars
RUN curl https://repo1.maven.org/maven2/org/apache/hudi/hudi-spark3-bundle_2.12/0.15.0/hudi-spark3-bundle_2.12-0.15.0.jar -Lo /opt/spark/jars/hudi-spark3-bundle_2.12-0.15.0.jar

COPY entrypoint.sh .
RUN chmod u+x /opt/spark/entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
CMD [ "bash" ]
