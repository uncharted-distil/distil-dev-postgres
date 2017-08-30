#!/bin/bash

source ./server/config.sh

HIGHLIGHT='\033[0;34m'
NC='\033[0m'

echo -e "${HIGHLIGHT}Getting distil-ingest..${NC}"

# get distil-ingest and force a static rebuild of it so that it can run on Alpine
go get -u -v github.com/unchartedsoftware/distil-ingest
CGO_ENABLED=0 go build -v -installsuffix cgo github.com/unchartedsoftware/distil-ingest/cmd/distil-ingest
mv distil-ingest ./server

# copy the d3m data into the docker context
echo -e "${HIGHLIGHT}Copying D3M data..${NC}"
mkdir -p ./server/data
for dataset in "${DATASETS[@]}"
do
    cp -r $DATA_PATH/$dataset ./server/data
done


echo -e "${HIGHLIGHT}Building image ${DOCKER_IMAGE_NAME}...${NC}"
cd server
docker build -t docker.uncharted.software/$DOCKER_IMAGE_NAME:${DOCKER_IMAGE_VERSION} .
cd ..
echo -e "${HIGHLIGHT}Done${NC}"
