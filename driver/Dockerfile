# Builder stage for Spark
FROM bjornjorgensen/spark-builder AS builder
ARG openjdk_version="21"


# Our main image starts here
FROM debian:testing

# Set environment variables to non-interactive (to avoid prompts during package installation)
ENV DEBIAN_FRONTEND noninteractive

# Update the package lists, install Python 3.11, and fetch tini
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    tini \
	"openjdk-${openjdk_version}-jre-headless" \
    ca-certificates-java && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Define default environment variables for user 'jovyan'
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="1000" # Updated GID to avoid conflicts

# Create jovyan user with the specified UID/GID
# If GID already exists, create the user without creating a new group
RUN if getent group ${NB_GID} ; then \
        useradd --no-log-init --create-home --shell /bin/bash --uid ${NB_UID} --gid ${NB_GID} ${NB_USER}; \
    else \
        groupadd --gid ${NB_GID} ${NB_USER} && \
        useradd --no-log-init --create-home --shell /bin/bash --uid ${NB_UID} --gid ${NB_GID} ${NB_USER}; \
    fi

# User setup and virtual environment creation
USER ${NB_USER}
WORKDIR /home/${NB_USER}

# Create a virtual environment and install JupyterLab
RUN python3.11 -m venv /home/${NB_USER}/venv && \
    /home/${NB_USER}/venv/bin/python -m pip install --no-cache-dir --upgrade \
        pip \
        setuptools \
        wheel && \
    /home/${NB_USER}/venv/bin/python -m pip install --no-cache-dir \
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
        pyarrow

# Make sure the virtual environment is activated on login
ENV PATH="/home/${NB_USER}/venv/bin:$PATH"


# Copy the Spark distribution from the builder stage
COPY --from=builder /tmp/spark/spark-4.0.0-SNAPSHOT-bin-custom-spark.tgz /tmp/spark.tgz

# Unpack Spark, move it to /opt/spark, and remove the tarball
RUN tar xzf /tmp/spark.tgz -C /usr/local --owner root --group root --no-same-owner && \
    rm /tmp/spark.tgz && \
    mv /usr/local/spark-4.0.0-SNAPSHOT-bin-custom-spark /opt/spark

# Configure Spark
ENV SPARK_HOME=/opt/spark
ENV PATH="${PATH}:${SPARK_HOME}/bin"

# Symlink (appears to be unnecessary as the directory is already moved to /opt/spark before)
# ln -s command may not be accurate depending on the actual contents. Adjust the source path accordingly.
# RUN ln -s /opt/spark /opt/spark

# Add S3A support
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.503/aws-java-sdk-bundle-1.12.503.jar ${SPARK_HOME}/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar ${SPARK_HOME}/jars/

# Update the permissions for the jars
RUN chmod a+rx ${SPARK_HOME}/jars/*.jar

# Switch back to jovyan user
USER ${NB_UID}

# JupyterLab extension 
RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

# Expose the port for JupyterLab
EXPOSE 8888

# Configure Tini as the entrypoint
ENTRYPOINT ["/usr/bin/tini", "--"]

# Start JupyterLab
CMD ["jupyter-lab", "--ip=0.0.0.0"]