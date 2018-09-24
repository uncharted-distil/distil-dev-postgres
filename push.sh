#!/bin/bash

source ./server/config.sh
docker login docker.uncharted.software
docker push docker.uncharted.software/distil_dev_postgres:latest
docker push docker.uncharted.software/distil_dev_postgres:${DOCKER_IMAGE_VERSION}
docker logout docker.uncharted.software
