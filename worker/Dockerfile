FROM bjornjorgensen/spark-builder AS builder

FROM debian:testing

USER root

ARG openjdk_version="21"
ARG spark_uid=185

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${openjdk_version}-jre" \
    ca-certificates-java \
    apt install -y bash tini libc6 libpam-modules krb5-user libnss3 procps net-tools && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/examples && \
    mkdir -p /opt/spark/work-dir && \
    touch /opt/spark/RELEASE && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*


COPY --from=builder /tmp/spark/dist/jars /opt/spark/jars
# Copy RELEASE file if exists
COPY --from=builder /tmp/spark/dist/RELEAS[E] /opt/spark/RELEASE
COPY --from=builder /tmp/spark/dist/bin /opt/spark/bin
COPY --from=builder /tmp/spark/dist/sbin /opt/spark/sbin
COPY --from=builder /tmp/spark/dist/kubernetes/dockerfiles/spark/entrypoint.sh /opt/
COPY --from=builder /tmp/spark/dist/kubernetes/dockerfiles/spark/decom.sh /opt/
COPY --from=builder /tmp/spark/dist/examples /opt/spark/examples
RUN ln -s $(basename $(ls /opt/spark/examples/jars/spark-examples_*.jar)) /opt/spark/examples/jars/spark-examples.jar
COPY --from=builder /tmp/spark/dist/kubernetes/tests /opt/spark/tests
COPY --from=builder /tmp/spark/dist/data /opt/spark/data

ENV SPARK_HOME /opt/spark
# Add S3A support
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.503/aws-java-sdk-bundle-1.12.503.jar ${SPARK_HOME}/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar ${SPARK_HOME}/jars/


WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh

ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
USER ${spark_uid}