#!/bin/bash

source ./server/config.sh
docker push docker.uncharted.software/distil_dev_postgres:latest
docker push docker.uncharted.software/distil_dev_postgres:${DOCKER_IMAGE_VERSION}
