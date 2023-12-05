FROM bjornjorgensen/spark-builder AS builder

FROM ubuntu:22.04

USER root

ARG openjdk_version="21"
ARG spark_uid=185

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --yes && \
    apt install -y "openjdk-${openjdk_version}-jre" ca-certificates-java bash tini libc6 libpam-modules krb5-user libnss3 procps net-tools curl bzip2 && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*

# Spark installation
WORKDIR /tmp



COPY --from=builder /tmp/spark/spark-4.0.0-SNAPSHOT-bin-custom-spark.tgz /tmp/spark.tgz

RUN tar xzf "spark.tgz" -C /usr/local --owner root --group root --no-same-owner && \
  rm "spark.tgz"

RUN mv /usr/local/spark-4.0.0-SNAPSHOT-bin-custom-spark /opt/spark

# Configure Spark
ENV SPARK_HOME=/opt/spark
ENV PATH="${PATH}:${SPARK_HOME}/bin"



RUN ln -s "spark" "${SPARK_HOME}";

RUN cp ${SPARK_HOME}/kubernetes/dockerfiles/spark/entrypoint.sh /opt/
RUN cp ${SPARK_HOME}/kubernetes/dockerfiles/spark/decom.sh /opt/

RUN ln -s $(basename $(ls /opt/spark/examples/jars/spark-examples_*.jar)) /opt/spark/examples/jars/spark-examples.jar
RUN cp -r ${SPARK_HOME}/kubernetes/tests /opt/spark/tests

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH="${CONDA_DIR}/bin:${PATH}"

# Pin the Python version here, or set it to "default"
ARG PYTHON_VERSION=3.11


# Download and install Micromamba, and initialize the Conda prefix.
#   <https://github.com/mamba-org/mamba#micromamba>
#   Similar projects using Micromamba:
#     - Micromamba-Docker: <https://github.com/mamba-org/micromamba-docker>
#     - repo2docker: <https://github.com/jupyterhub/repo2docker>
# Install Python, Mamba
# Cleanup temporary files and remove Micromamba
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change

WORKDIR /tmp

RUN set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        arch="64"; \
    elif [ "${arch}" = "aarch64" ]; then \
        arch="aarch64"; \
    elif [ "${arch}" = "ppc64le" ]; then \
        arch="ppc64le"; \
    fi && \
    curl -Ls "https://micro.mamba.pm/api/micromamba/linux-${arch}/latest" | tar -xvj bin/micromamba && \
    mv bin/micromamba ./micromamba && \
    chmod +x ./micromamba && \
    rm -rf bin && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi && \
    ./micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        "${PYTHON_SPECIFIER}" \
        'mamba' && \
    rm ./micromamba && \
    mamba list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    mamba clean --all -f -y

# Add S3A support
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.503/aws-java-sdk-bundle-1.12.503.jar ${SPARK_HOME}/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar ${SPARK_HOME}/jars/

RUN chmod a+rx ${SPARK_HOME}/jars/*.jar
WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh

ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
USER ${spark_uid}