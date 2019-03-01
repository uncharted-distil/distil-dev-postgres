#!/bin/bash

source ./server/config.sh

docker run \
  -p 5432:5432 \
  --rm \
  --name $DOCKER_IMAGE_NAME \
  $DOCKER_REPO/$DOCKER_IMAGE_NAME:${DOCKER_IMAGE_VERSION} \
  -d postgres
