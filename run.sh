#!/bin/bash

source ./server/config.sh

docker run \
  --name $DOCKER_IMAGE_NAME \
  -e POSTGRES_USER=distil -e POSTGRES_PASSWORD=gopher! -e POSTGRES_DB=distil \
  -p 5432:5432 \
  -d postgres
