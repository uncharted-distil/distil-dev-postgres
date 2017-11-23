#!/bin/bash

source ./server/config.sh

HIGHLIGHT='\033[0;34m'
NC='\033[0m'

echo -e "${HIGHLIGHT}Getting distil-ingest..${NC}"

# get distil-ingest and force a static rebuild of it so that it can run on Alpine
go get -u -v github.com/unchartedsoftware/distil-ingest/cmd/distil-merge
go get -u -v github.com/unchartedsoftware/distil-ingest/cmd/distil-classify
go get -u -v github.com/unchartedsoftware/distil-ingest/cmd/distil-rank
go get -u -v github.com/unchartedsoftware/distil-ingest/cmd/distil-ingest
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/unchartedsoftware/distil-ingest/cmd/distil-merge
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/unchartedsoftware/distil-ingest/cmd/distil-classify
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/unchartedsoftware/distil-ingest/cmd/distil-rank
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/unchartedsoftware/distil-ingest/cmd/distil-ingest
mv distil-merge ./server
mv distil-classify ./server
mv distil-rank ./server
mv distil-ingest ./server

# copy the d3m data into the docker context
echo -e "${HIGHLIGHT}Copying D3M data..${NC}"
mkdir -p ./server/data/d3m
for DATASET in "${DATASETS[@]}"
do
    echo "cp $HOST_DATA_DIR/$DATASET into ./server/data/d3m/$DATASET"
    cp -r $HOST_DATA_DIR/$DATASET ./server/data/d3m
done

# start classification REST API container
docker run -d --rm --name classification_rest -p 5000:5000 primitives.azurecr.io/data.world_container:v1.0
./wait-for-it.sh -t 0 localhost:5000
echo "Waiting for the service to be available..."
sleep 10

# start ranking REST API container
docker run -d --rm --name ranking_rest  -p 5001:5000 primitives.azurecr.io/http_features:0.2
./wait-for-it.sh -t 0 localhost:5001
echo "Waiting for the service to be available..."
sleep 10

echo -e "${HIGHLIGHT}Building image ${DOCKER_IMAGE_NAME}...${NC}"
cd server
docker build --no-cache --network=host \
    --build-arg smmry_key=$SMMRY_API_KEY  \
    -t docker.uncharted.software/$DOCKER_IMAGE_NAME:${DOCKER_IMAGE_VERSION} -t docker.uncharted.software/$DOCKER_IMAGE_NAME:latest .
cd ..

# stop classification REST API container
docker stop classification_rest

# stop ranking REST API container
docker stop ranking_rest

echo -e "${HIGHLIGHT}Done${NC}"
