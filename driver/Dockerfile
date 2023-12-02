# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
FROM bjornjorgensen/spark-builder AS builder

#ARG REGISTRY=quay.io
#ARG OWNER=jupyter
#ARG BASE_CONTAINER=$REGISTRY/$OWNER/scipy-notebook
FROM quay.io/jupyter/scipy-notebook:latest

ARG openjdk_version="21"

USER root

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${openjdk_version}-jre-headless" \
    ca-certificates-java && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Spark installation
WORKDIR /tmp



COPY --from=builder /tmp/spark/spark-4.0.0-SNAPSHOT-bin-custom-spark.tgz /tmp/spark.tgz

RUN tar xzf "spark.tgz" -C /usr/local --owner root --group root --no-same-owner && \
  rm "spark.tgz"

RUN mv /usr/local/spark-4.0.0-SNAPSHOT-bin-custom-spark /usr/local/spark

# Configure Spark
ENV SPARK_HOME=/usr/local/spark
ENV PATH="${PATH}:${SPARK_HOME}/bin"


RUN ls /usr/local/spark
RUN ln -s "spark" "${SPARK_HOME}"; \
  # Add a link in the before_notebook hook in order to source automatically PYTHONPATH && \
  ln -s "${SPARK_HOME}/sbin/spark-config.sh" /usr/local/bin/before-notebook.d/spark-config.sh



# Add S3A support
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.503/aws-java-sdk-bundle-1.12.503.jar ${SPARK_HOME}/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar ${SPARK_HOME}/jars/

RUN chmod a+rx ${SPARK_HOME}/jars/*.jar
# Switch back to jovyan to avoid accidental container runs as root

RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"
# Configure IPython system-wide
COPY ipython_kernel_config.py "/etc/ipython/"
RUN fix-permissions "/etc/ipython/"

USER ${NB_UID}

# Install pyarrow
# NOTE: It's important to ensure compatibility between Pandas versions.
# The pandas version in this Dockerfile should match the version
# on which the Pandas API for Spark is built.
# To find the right version:
# 1. Check out the Spark branch you are on.
# 2. Find the pandas version in the file spark/dev/infra/Dockerfile.
RUN mamba install --yes \
    'grpcio-status' \
    'grpcio' \
    'pandas' \
    'pyarrow' && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

WORKDIR "${HOME}"
EXPOSE 4040