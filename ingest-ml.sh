#!/bin/bash

source ./server/config.sh

env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-merge@$BRANCH
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-classify@$BRANCH
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-rank@$BRANCH
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-ingest@$BRANCH
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-summary@$BRANCH
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-featurize@$BRANCH
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-cluster@$BRANCH
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-geocode@$BRANCH
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-format@$BRANCH
env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-clean@$BRANCH
mv $GOPATH/bin/distil-merge ./server
mv $GOPATH/bin/distil-classify ./server
mv $GOPATH/bin/distil-rank ./server
mv $GOPATH/bin/distil-ingest ./server
mv $GOPATH/bin/distil-summary ./server
mv $GOPATH/bin/distil-featurize ./server
mv $GOPATH/bin/distil-cluster ./server
mv $GOPATH/bin/distil-geocode ./server
mv $GOPATH/bin/distil-format ./server
mv $GOPATH/bin/distil-clean ./server

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
    --name distil-auto-ml \
    --rm \
    -d \
    -p 45042:45042 \
    --env D3MOUTPUTDIR=$OUTPUT_DATA_DIR \
    --env D3MINPUTDIR=$HOST_DATA_DIR_COPY \
    --env D3MSTATICDIR=$D3MSTATICDIR \
    --env PROGRESS_INTERVAL=60 \
    -v $HOST_DATA_DIR_COPY:$HOST_DATA_DIR_COPY \
    -v $OUTPUT_DATA_DIR:$OUTPUT_DATA_DIR \
    -v $D3MSTATICDIR:$D3MSTATICDIR \
    registry.datadrivendiscovery.org/uncharted/distil-integration/distil-auto-ml:latest
echo "Waiting for the pipeline runner to be available..."
sleep 60

SCHEMA=/datasetDoc.json
HAS_HEADER=1
PRIMITIVE_ENDPOINT=localhost:45042
DATA_LOCATION=/tmp/d3m/input
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
        --dataset="${DATASET}" \
        --media-path="$DATA_LOCATION/${DATASET}/TRAIN/dataset_TRAIN/" \
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
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
        --dataset="${DATASET}" \
        --media-path="$DATA_LOCATION/${DATASET}/TRAIN/dataset_TRAIN/" \
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$OUTPUT_DATA_DIR/${DATASET}/$CLUSTER_OUTPUT_SCHEMA" \
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
        --dataset="${DATASET}" \
        --raw-data="$HOST_DATA_DIR_COPY/${DATASET}/TRAIN/dataset_TRAIN/" \
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$OUTPUT_DATA_DIR/${DATASET}/$FEATURE_OUTPUT_SCHEMA" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_DATASET_FOLDER" \
        --has-header=$MERGE_HAS_HEADER
done

FORMAT_OUTPUT_FOLDER=format
FORMAT_OUTPUT_DATA=format/tables/learningData.csv
FORMAT_OUTPUT_SCHEMA=format/datasetDoc.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " FORMATTING $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-format \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --dataset="${DATASET}" \
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$OUTPUT_DATA_DIR/${DATASET}/$MERGED_OUTPUT_SCHEMA" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$FORMAT_OUTPUT_FOLDER" \
        --output-schema="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$FORMAT_OUTPUT_SCHEMA" \
        --has-header=$HAS_HEADER
done

CLEANING_OUTPUT_SCHEMA=clean/datasetDoc.json
CLEANING_DATASET_FOLDER=clean

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Cleaning $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-clean \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$OUTPUT_DATA_DIR/${DATASET}/$FORMAT_OUTPUT_SCHEMA" \
        --dataset="${DATASET}" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLEANING_DATASET_FOLDER"
done

CLASSIFICATION_OUTPUT_PATH=classification.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Classifying $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./server/distil-classify \
        --endpoint="$PRIMITIVE_ENDPOINT" \
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$OUTPUT_DATA_DIR/${DATASET}/$CLEANING_OUTPUT_SCHEMA" \
        --dataset="${DATASET}" \
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
        --input="$HOST_DATA_DIR_COPY" \
        --schema="$OUTPUT_DATA_DIR/${DATASET}/$CLEANING_OUTPUT_SCHEMA" \
        --dataset="${DATASET}" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$IMPORTANCE_OUTPUT"
done

SUMMARY_MACHINE_OUTPUT=summary-machine.json

# Duke fails on large dataset (geolife)
for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Summarizing $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    if [ "$DATASET" == "LL1_336_MS_Geolife_transport_mode_prediction_separate_lat_lon" ];
    then
        echo "SKIPPING SUMMARY"
    else
        ./server/distil-summary \
            --endpoint="$PRIMITIVE_ENDPOINT" \
            --input="$HOST_DATA_DIR_COPY" \
            --schema="$OUTPUT_DATA_DIR/${DATASET}/$CLEANING_OUTPUT_SCHEMA" \
            --dataset="${DATASET}" \
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
        --input="$HOST_DATA_DIR_COPY" \
        --dataset="${DATASET}" \
        --classification="$OUTPUT_DATA_DIR/${DATASET}/$CLASSIFICATION_OUTPUT_PATH" \
        --schema="$OUTPUT_DATA_DIR/${DATASET}/$CLEANING_OUTPUT_SCHEMA" \
        --output="$OUTPUT_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$GEO_OUTPUT_FOLDER" \
        --has-header=$HAS_HEADER
done
