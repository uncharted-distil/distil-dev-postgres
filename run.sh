#!/bin/bash

source ./server/config.sh

docker run \
  -p 5432:5432 \
  --name $DOCKER_IMAGE_NAME \
  docker.uncharted.software/$DOCKER_IMAGE_NAME:${DOCKER_IMAGE_VERSION} \
  -d postgres
