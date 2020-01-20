#!/bin/bash

source ./server/config.sh

HIGHLIGHT='\033[0;34m'
NC='\033[0m'

echo -e "${HIGHLIGHT}Getting distil-ingest..${NC}"

# get distil-ingest and force a static rebuild of it so that it can run on Alpine
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-ingest@$BRANCH
mv $GOPATH/bin/distil-ingest ./server

# copy the d3m data into the docker context
echo -e "${HIGHLIGHT}Copying D3M data..${NC}"
mkdir -p ./server/data
cp -r $OUTPUT_DATA_DIR ./server/data
rm -rf ./server/data/d3m
mv ./server/data/output ./server/data/d3m

echo -e "${HIGHLIGHT}Building image ${DOCKER_IMAGE_NAME}...${NC}"
cd server
docker build --squash --no-cache --network=host \
    -t $DOCKER_REPO/$DOCKER_IMAGE_NAME:${DOCKER_IMAGE_VERSION} -t $DOCKER_REPO/$DOCKER_IMAGE_NAME:latest .
cd ..

echo -e "${HIGHLIGHT}Done${NC}"
