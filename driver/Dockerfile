# Builder stage for Spark
FROM bjornjorgensen/spark-builder AS builder

# Our main image starts here
FROM debian:testing

# Set environment variables to non-interactive (to avoid prompts during package installation)
ENV DEBIAN_FRONTEND noninteractive

# Define the OpenJDK version
ARG openjdk_version="21"

# Update the package lists, install Python 3.11, tini, OpenJDK, and required certificates
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    tini \
    procps \
    "openjdk-${openjdk_version}-jdk" \
    ca-certificates-java && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Define default environment variables for user 'jovyan'
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="1000"

# Create jovyan user with the specified UID/GID and ensure directory permissions are correct
RUN groupadd --gid "${NB_GID}" "${NB_USER}" && \
    useradd --no-log-init --create-home --shell /bin/bash --uid "${NB_UID}" --gid "${NB_GID}" "${NB_USER}" && \
    mkdir -p "/home/${NB_USER}" && \
    chown -R "${NB_UID}:${NB_GID}" "/home/${NB_USER}"



# As root user create the virtual environment
RUN python3.11 -m venv /opt/venv && \
    chown -R ${NB_UID}:${NB_GID} /opt/venv

# Switch to the jovyan user
USER "${NB_USER}"
WORKDIR "/home/${NB_USER}"

# Set the PATH to include the virtual environment's executables
ENV PATH="/opt/venv/bin:${PATH}"



# Install packages using pip in the virtual environment
RUN pip install --no-cache-dir --upgrade \
        pip \
        setuptools \
        wheel && \
    pip install --no-cache-dir \
        jupyterlab \
        'black[jupyter]' \
        xmltodict \
        jupyterlab-code-formatter \
        isort \
        python-dotenv \
        nbdev \
        lxml \
        jupyter_ai \
        plotly \
        pygwalker \
        psycopg2-binary \
        sqlalchemy \
        pyarrow \
        pandas


USER root
# Copy the Spark distribution from the builder stage
COPY --from=builder /tmp/spark/spark-4.0.0-SNAPSHOT-bin-custom-spark.tgz /tmp/spark.tgz

# Unpack Spark, move it to /opt/spark, and remove the tarball
RUN tar xzf /tmp/spark.tgz -C /usr/local && \
    rm /tmp/spark.tgz && \
    mv /usr/local/spark-4.0.0-SNAPSHOT-bin-custom-spark /opt/spark

# Configure Spark paths
ENV SPARK_HOME="/opt/spark"
ENV PATH="${SPARK_HOME}/bin:${PATH}"


#USER "${NB_USER}"
# Install PySpark from the local Spark directory
RUN pip install -e /opt/spark/python

USER root
# Add Jars for S3A support to the Spark Jars directory and update the permissions
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.503/aws-java-sdk-bundle-1.12.503.jar ${SPARK_HOME}/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar ${SPARK_HOME}/jars/
RUN chmod a+rx ${SPARK_HOME}/jars/*.jar

# Expose the port for JupyterLab
EXPOSE 8888

RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

# Copy the entrypoint script into the container and set permissions
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Switch to the jovyan user
USER "${NB_USER}"
WORKDIR "/home/${NB_USER}"

# Set the entrypoint to the script
ENTRYPOINT ["/docker-entrypoint.sh"]

# Start JupyterLab
CMD ["jupyter-lab", "--ip=0.0.0.0", "--no-browser"]



