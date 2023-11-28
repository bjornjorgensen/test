# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
FROM bjornjorgensen/spark-builder AS builder

FROM debian:testing


ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"
ARG openjdk_version="21"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Install all OS dependencies for the Server that starts
# but lacks all features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --yes && \
    # - `apt-get upgrade` is run to patch known vulnerabilities in apt-get packages as
    #   the Ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    ca-certificates \
    locales \
    sudo \
    # - tini is installed as a helpful container entrypoint that reaps zombie
    #   processes and such of the actual executable we want to start, see
    #   https://github.com/krallin/tini#why-tini for details.
    tini \
    python3 \
    python3-pip \
    python3.11-venv \
    "openjdk-${openjdk_version}-jdk-headless" \
    "openjdk-${openjdk_version}-jre" \
    ca-certificates-java \
    wget && \
    python3 -m venv /opt/venv \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Activate virtual environment
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install jupyterlab --upgrade pip setuptools 'black[jupyter]' xmltodict jupyterlab-code-formatter isort python-dotenv nbdev lxml jupyter_ai plotly pyspark-ai pygwalker psycopg2-binary sqlalchemy pyarrow

ENV JUPYTER_PORT=8888
EXPOSE $JUPYTER_PORT


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

RUN mkdir /opt/spark/work-dir
# Note: don't change the workdir since then your Jupyter notebooks won't persist.
RUN chmod g+w /opt/spark/work-dir
# Wildcard so it covers decom.sh present (3.1+) and not present (pre-3.1)
RUN chmod a+x /opt/decom.sh* || echo "No decom script present, assuming pre-3.1"

ENV SPARK_HOME /opt/spark

# Copy pyspark with setup files and everything
#COPY --from=builder /tmp/spark/dist/python ${SPARK_HOME}/python
COPY --from=builder /tmp/spark/dist/python/pyspark ${SPARK_HOME}/python/pyspark
COPY --from=builder /tmp/spark/dist/python/lib ${SPARK_HOME}/python/lib
# Add PySpark to PYTHON_PATH
#RUN pip install -e ${SPARK_HOME}/python



# Add S3A support
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.503/aws-java-sdk-bundle-1.12.503.jar ${SPARK_HOME}/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar ${SPARK_HOME}/jars/

RUN chmod a+rx ${SPARK_HOME}/jars/*.jar

# Configure container startup
CMD ["start-notebook.py"]

# Copy local files as late as possible to avoid cache busting
COPY start-notebook.py start-notebook.sh start-singleuser.py start-singleuser.sh /usr/local/bin/
COPY jupyter_server_config.py docker_healthcheck.py /etc/jupyter/


# Configure environment
ENV SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV HOME="/home/${NB_USER}"

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
   # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
   echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

# Create NB_USER with name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd --no-log-init --create-home --shell /bin/bash --uid "${NB_UID}" --no-user-group "${NB_USER}" && \
    chmod g+w /etc/passwd && \
    fix-permissions "/home/${NB_USER}"

USER ${NB_UID}


# Setup work directory for backward-compatibility
RUN mkdir "/home/${NB_USER}/work" && \
    fix-permissions "/home/${NB_USER}"



USER root

# Copy local files as late as possible to avoid cache busting
COPY run-hooks.sh start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

# Configure container startup


# Create dirs for startup hooks
RUN mkdir /usr/local/bin/start-notebook.d && \
    mkdir /usr/local/bin/before-notebook.d

# HEALTHCHECK documentation: https://docs.docker.com/engine/reference/builder/#healthcheck
# This healtcheck works well for `lab`, `notebook`, `nbclassic`, `server`, and `retro` jupyter commands
# https://github.com/jupyter/docker-stacks/issues/915#issuecomment-1068528799
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
    CMD /etc/jupyter/docker_healthcheck.py || exit 1

# Switch back to jovyan to avoid accidental container runs as root

RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"
WORKDIR ${HOME}
USER ${NB_USER}

EXPOSE 8888
ENTRYPOINT ["tini", "--"]
CMD ["jupyter", "lab"]
