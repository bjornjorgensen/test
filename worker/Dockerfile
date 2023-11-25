FROM bjornjorgensen/sparkbuilder AS builder


USER root

ARG openjdk_version="21"


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


#USER ${NB_UID} 
RUN pip install -e python  

WORKDIR /opt/spark
ENV SPARK_HOME /opt/spark


RUN fix-permissions "${SPARK_HOME}" && \
    fix-permissions "/opt/spark/jars" && \
    fix-permissions "/opt/spark/bin" && \
    fix-permissions "/opt/spark/sbin" && \
    fix-permissions "/opt/spark/examples" && \
    fix-permissions "/opt/spark/data" && \
    fix-permissions "/opt/spark/LICENSE" && \
    fix-permissions "/opt/spark/python" && \
    fix-permissions "/opt/spark/licenses"

RUN chmod a+x /opt/decom.sh* || echo "No decom script present, assuming pre-3.1"

RUN fix-permissions "${SPARK_HOME}" && \
    fix-permissions "/home/${NB_USER}" && \
    fix-permissions "/home/jovyan/.cache/"

RUN fix-permissions "/home/${NB_USER}"

# Add S3A support
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.503/aws-java-sdk-bundle-1.12.503.jar ${SPARK_HOME}/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar ${SPARK_HOME}/jars/

RUN chmod a+rx ${SPARK_HOME}/jars/*.jar 

# Configure IPython system-wide
COPY ipython_kernel_config.py "/etc/ipython/"
RUN fix-permissions "/etc/ipython/"


WORKDIR "${HOME}"

USER ${NB_UID}

# Should match the service
EXPOSE 2222
EXPOSE 7777
