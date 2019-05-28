#!/bin/bash

source ./server/config.sh

go get -u -v github.com/uncharted-distil/distil-ingest/cmd/distil-merge
go get -u -v github.com/uncharted-distil/distil-ingest/cmd/distil-classify
go get -u -v github.com/uncharted-distil/distil-ingest/cmd/distil-rank
go get -u -v github.com/uncharted-distil/distil-ingest/cmd/distil-ingest
go get -u -v github.com/uncharted-distil/distil-ingest/cmd/distil-summary
go get -u -v github.com/uncharted-distil/distil-ingest/cmd/distil-featurize
go get -u -v github.com/uncharted-distil/distil-ingest/cmd/distil-cluster
go get -u -v github.com/uncharted-distil/distil-ingest/cmd/distil-geocode
go get -u -v github.com/uncharted-distil/distil-ingest/cmd/distil-format
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/uncharted-distil/distil-ingest/cmd/distil-merge
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/uncharted-distil/distil-ingest/cmd/distil-classify
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/uncharted-distil/distil-ingest/cmd/distil-rank
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/uncharted-distil/distil-ingest/cmd/distil-ingest
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/uncharted-distil/distil-ingest/cmd/distil-summary
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/uncharted-distil/distil-ingest/cmd/distil-featurize
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/uncharted-distil/distil-ingest/cmd/distil-cluster
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/uncharted-distil/distil-ingest/cmd/distil-geocode
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a github.com/uncharted-distil/distil-ingest/cmd/distil-format
mv distil-merge ./server
mv distil-classify ./server
mv distil-rank ./server
mv distil-ingest ./server
mv distil-summary ./server
mv distil-featurize ./server
mv distil-cluster ./server
mv distil-geocode ./server
mv distil-format ./server

rm -rf $HOST_DATA_DIR_COPY
mkdir -p $HOST_DATA_DIR_COPY
for DATASET in "${DATASETS_SEED[@]}"
do
    echo "cp $HOST_DATA_DIR/$DATASET into $HOST_DATA_DIR_COPY/$DATASET"
    cp -r $HOST_DATA_DIR/$DATASET $HOST_DATA_DIR_COPY
done

for DATASET in "${DATASETS_EVAL[@]}"
do
    echo "cp $HOST_DATA_DIR_EVAL/$DATASET into $HOST_DATA_DIR_COPY/$DATASET"
    cp -r $HOST_DATA_DIR_EVAL/$DATASET $HOST_DATA_DIR_COPY
done

for DATASET in "${DATASETS_DA[@]}"
do
    echo "cp $HOST_DATA_DIR_DA/$DATASET into $HOST_DATA_DIR_COPY/$DATASET"
    cp -r $HOST_DATA_DIR_DA/$DATASET $HOST_DATA_DIR_COPY
done

rm -rf $OUTPUT_DATA_DIR
mkdir -p $OUTPUT_DATA_DIR
docker run \
    --name pipeline-runner \
    --rm \
    -d \
    -p 50051:50051 \
    --env D3MOUTPUTDIR=$OUTPUT_DATA_DIR \
    --env D3MINPUTDIR=$HOST_DATA_DIR_COPY \
    --env D3MSTATICDIR=$D3MSTATICDIR \
    --env VERBOSE_PRIMITIVE_OUTPUT=true \
    -v $HOST_DATA_DIR_COPY:$HOST_DATA_DIR_COPY \
    -v $OUTPUT_DATA_DIR:$OUTPUT_DATA_DIR \
    -v $D3MSTATICDIR:$D3MSTATICDIR \
    $DOCKER_REPO/distil-pipeline-runner:latest
echo "Waiting for the pipeline runner to be available..."
sleep 60

SCHEMA=/datasetDoc.json
FORMAT_OUTPUT_FOLDER=format
FORMAT_OUTPUT_DATA=format/tables/learningData.csv
FORMAT_OUTPUT_SCHEMA=format/datasetDoc.json
HAS_HEADER=1
PRIMITIVE_ENDPOINT=localhost:50051
DATA_LOCATION=/tmp/d3m/input

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " FORMATTING $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-format \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
        --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$FORMAT_OUTPUT_FOLDER" \
        --output-schema="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$FORMAT_OUTPUT_SCHEMA" \
        --has-header=$HAS_HEADER
done

CLUSTER_OUTPUT_FOLDER=clusters
CLUSTER_OUTPUT_DATA=clusters/tables/learningData.csv
CLUSTER_OUTPUT_SCHEMA=clusters/datasetDoc.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Clustering $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-cluster \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$FORMAT_OUTPUT_SCHEMA" \
        --media-path="$DATA_LOCATION/${DATASET}/TRAIN/dataset_TRAIN/" \
        --schema="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$FORMAT_OUTPUT_SCHEMA" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLUSTER_OUTPUT_FOLDER" \
        --output-schema="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLUSTER_OUTPUT_SCHEMA" \
        --has-header=$HAS_HEADER
done

FEATURE_OUTPUT_FOLDER=features
FEATURE_OUTPUT_DATA=features/tables/learningData.csv
FEATURE_OUTPUT_SCHEMA=features/datasetDoc.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Featurizing $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-featurize \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLUSTER_OUTPUT_SCHEMA" \
        --media-path="$DATA_LOCATION/${DATASET}/TRAIN/dataset_TRAIN/" \
        --schema="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLUSTER_OUTPUT_SCHEMA" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$FEATURE_OUTPUT_FOLDER" \
        --has-header=$HAS_HEADER
done

MERGED_DATASET_FOLDER=merged
MERGED_OUTPUT_PATH=merged/tables/mergedNoHeader.csv
MERGED_OUTPUT_PATH_RELATIVE=tables/learningData.csv
MERGED_OUTPUT_HEADER_PATH=merged/tables/learningData.csv
MERGED_OUTPUT_SCHEMA=merged/datasetDoc.json
MERGE_HAS_HEADER=1

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Merging $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-merge \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$FEATURE_OUTPUT_SCHEMA" \
        --raw-data="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_DATASET_FOLDER" \
        --output-path-relative="$MERGED_OUTPUT_PATH_RELATIVE" \
        --output-path-header="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_HEADER_PATH" \
        --output-schema-path="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_SCHEMA" \
        --has-header=$MERGE_HAS_HEADER
done

CLASSIFICATION_OUTPUT_PATH=classification.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Classifying $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-classify \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_DATASET_FOLDER" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLASSIFICATION_OUTPUT_PATH"
done

IMPORTANCE_OUTPUT=importance.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Ranking $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-rank \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_DATASET_FOLDER" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$IMPORTANCE_OUTPUT"
done

SUMMARY_MACHINE_OUTPUT=summary-machine.json

# Duke fails on large dataset (geolife)
for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Summarizing $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    if [ "$DATASET" == "LL1_336_MS_Geolife_transport_mode_prediction" ];
    then
        echo "SKIPPING SUMMARY"
    else
        ./server/distil-summary \
            --endpoint="$PRIMITIVE_ENDPOINT" \
            --dataset="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_DATASET_FOLDER" \
            --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SUMMARY_MACHINE_OUTPUT"
    fi
done

GEO_OUTPUT_FOLDER=geocoded
GEO_OUTPUT_DATA=geocoded/tables/learningData.csv
GEO_OUTPUT_SCHEMA=geocoded/datasetDoc.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Geocoding $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-geocode \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_SCHEMA" \
        --classification="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLASSIFICATION_OUTPUT_PATH" \
        --schema="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_SCHEMA" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$GEO_OUTPUT_FOLDER" \
        --has-header=$HAS_HEADER
done
