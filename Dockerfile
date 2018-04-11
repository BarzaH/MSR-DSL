FROM openjdk:8

ARG ZEPPELIN_VERSION="0.7.2"
ARG SPARK_VERSION="2.1.1"
ARG HADOOP_VERSION="2.7"


# Scala related variables.
ARG SCALA_VERSION=2.12.2
ARG SCALA_BINARY_ARCHIVE_NAME=scala-${SCALA_VERSION}
ARG SCALA_BINARY_DOWNLOAD_URL=http://downloads.lightbend.com/scala/${SCALA_VERSION}/${SCALA_BINARY_ARCHIVE_NAME}.tgz

# SBT related variables.
ARG SBT_VERSION=0.13.15
ARG SBT_BINARY_ARCHIVE_NAME=sbt-$SBT_VERSION
ARG SBT_BINARY_DOWNLOAD_URL=https://dl.bintray.com/sbt/native-packages/sbt/${SBT_VERSION}/${SBT_BINARY_ARCHIVE_NAME}.tgz

ENV SCALA_HOME  /usr/local/scala
ENV SBT_HOME    /usr/local/sbt
ENV PATH        $JAVA_HOME/bin:$SCALA_HOME/bin:$SBT_HOME/bin:$PATH


LABEL maintainer "mirkoprescha"
LABEL zeppelin.version=${ZEPPELIN_VERSION}
LABEL spark.version=${SPARK_VERSION}
LABEL hadoop.version=${HADOOP_VERSION}

# Install some tools
RUN apt-get -y update &&\
    apt-get -y install curl less &&\
    apt-get -y install vim


# Install Scala and SBT tools
RUN apt-get -yqq update && \
    apt-get install -yqq vim screen tmux && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    wget -qO - ${SCALA_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/ && \
    wget -qO - ${SBT_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/  && \
    cd /usr/local/ && \
    ln -s ${SCALA_BINARY_ARCHIVE_NAME} scala


COPY repodriller_jar /repodriller_jar



##########################################
# Postgres DB
##########################################
COPY create_db_tables.sh /

RUN apt-get -yqq update &&\
apt-get -y install postgresql postgresql-contrib &&\
sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/g' /etc/postgresql/9.6/main/pg_hba.conf &&\
sed -i 's/local   all             all                                peer/local   all             all                                trust/g' /etc/postgresql/9.6/main/pg_hba.conf &&\
sed -i 's/peer/trust/g' /etc/postgresql/9.6/main/pg_hba.conf


RUN service postgresql restart 

RUN /etc/init.d/postgresql start &&\
psql -U postgres --command "CREATE DATABASE soft_metrics;" &&\
psql -U postgres --command "CREATE USER msr WITH PASSWORD 'root'; GRANT ALL ON DATABASE soft_metrics TO msr;" 
# sed -i 's/local   all             msr                                peer/local   all             msr                                trust/g' /etc/postgresql/9.6/main/pg_hba.conf &&\
# sed -i 's/peer/trust/g' /etc/postgresql/9.6/main/pg_hba.conf &&\

RUN service postgresql stop 
RUN service postgresql start

# RUN /etc/init.d/postgresql start

RUN chmod +x /create_db_tables.sh
# RUN ./create_db_tables.sh


##########################################
# SPARK
##########################################
ARG SPARK_ARCHIVE=http://d3kbcqa49mib13.cloudfront.net/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN mkdir /usr/local/spark &&\
    mkdir /tmp/spark-events    # log-events for spark history server
ENV SPARK_HOME /usr/local/spark

ENV PATH $PATH:${SPARK_HOME}/bin
RUN curl -s ${SPARK_ARCHIVE} | tar -xz -C  /usr/local/spark --strip-components=1

COPY spark-defaults.conf ${SPARK_HOME}/conf/



##########################################
# Zeppelin
##########################################
RUN mkdir /usr/zeppelin &&\
    curl -s http://mirror.softaculous.com/apache/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz | tar -xz -C /usr/zeppelin

RUN echo '{ "allow_root": true }' > /root/.bowerrc

ENV ZEPPELIN_PORT 8080
EXPOSE $ZEPPELIN_PORT

ENV ZEPPELIN_HOME /usr/zeppelin/zeppelin-${ZEPPELIN_VERSION}-bin-all
ENV ZEPPELIN_CONF_DIR $ZEPPELIN_HOME/conf
ENV ZEPPELIN_NOTEBOOK_DIR $ZEPPELIN_HOME/notebook

RUN mkdir -p $ZEPPELIN_HOME \
  && mkdir -p $ZEPPELIN_HOME/logs \
  && mkdir -p $ZEPPELIN_HOME/run

COPY zeppelin-env.sh ${ZEPPELIN_HOME}/conf/




COPY test-repos /test-repos

# my WorkDir
RUN mkdir /work
WORKDIR /work




CMD ["/bin/bash"]

