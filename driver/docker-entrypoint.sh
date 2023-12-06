#!/bin/bash

# Activate the virtual environment
source /opt/venv/bin/activate

# Execute the command specified as CMD in Dockerfile or passed to docker run
exec "$@"