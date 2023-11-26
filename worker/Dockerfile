FROM bjornjorgensen/spark-builder AS builder

FROM debian:testing

USER root

ARG openjdk_version="21"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${openjdk_version}-jdk-headless" \
    "openjdk-${openjdk_version}-jre" \
    ca-certificates-java \
    wget \
    python3 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
 

COPY --from=builder /tmp/spark/jars /opt/spark/jars
COPY --from=builder /tmp/spark/bin /opt/spark/bin
COPY --from=builder /tmp/spark/sbin /opt/spark/sbin
COPY --from=builder /tmp/spark/kubernetes/dockerfiles/spark/entrypoint.sh /opt/
COPY --from=builder /tmp/spark/kubernetes/dockerfiles/spark/decom.sh* /opt/
COPY --from=builder /tmp/spark/examples /opt/spark/examples
COPY --from=builder /tmp/spark/data /opt/spark/data
COPY --from=builder /tmp/spark/LICENSE /opt/spark/LICENSE
COPY --from=builder /tmp/spark/licenses /opt/spark/licenses
COPY --from=builder /tmp/spark/python /opt/spark/python

#WORKDIR /opt/spark
#USER ${NB_UID} 
#RUN pip install -e python  

WORKDIR /opt/spark
ENV SPARK_HOME /opt/spark


RUN chmod a+x /opt/decom.sh* || echo "No decom script present, assuming pre-3.1"


# Add S3A support
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.503/aws-java-sdk-bundle-1.12.503.jar ${SPARK_HOME}/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar ${SPARK_HOME}/jars/

RUN chmod a+rx ${SPARK_HOME}/jars/*.jar 



WORKDIR /opt/spark/work-dir
ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
ARG spark_uid=185
USER ${spark_uid}


# Should match the service
EXPOSE 2222
EXPOSE 7777
