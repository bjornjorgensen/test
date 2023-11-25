FROM debian:testing AS dep-builder

ARG openjdk_version="21"

USER root

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${openjdk_version}-jdk" \
    "openjdk-${openjdk_version}-jre-headless" \
    ca-certificates-java \
    git wget python3 python3-venv && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    python3 -m venv /opt/venv

# Activate virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# Now use pip to install packages
RUN pip install --upgrade pip setuptools



WORKDIR /tmp/

RUN git clone https://github.com/apache/spark.git

WORKDIR /tmp/spark 

RUN ./dev/make-distribution.sh --name custom-spark --pip -Pkubernetes

RUN rm -rf /tmp/spark