#!/bin/bash

source ./config.sh

SCHEMA=/datasetDoc.json
HAS_HEADER=1
GEOCODED_OUTPUT_PATH=geocoded/tables/learningData.csv
OUTPUT_SCHEMA=geocoded/datasetDoc.json
CLASSIFICATION_OUTPUT_PATH=classification.json
IMPORTANCE_OUTPUT=importance.json
SUMMARY_MACHINE_OUTPUT=summary-machine.json
METADATA_INDEX=datasets
POSTGRES_HOST=127.0.0.1
SUMMARY_OUTPUT_PATH=summary.txt
TYPE_SOURCE=classification

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Ingesting $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-ingest \
        --database=distil \
        --db-table="d_$DATASET" \
        --db-user=distil \
        --db-password=gopher! \
        --dataset-folder="$DATASET" \
        --schema="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$OUTPUT_SCHEMA" \
        --dataset="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$GEOCODED_OUTPUT_PATH" \
        --classification="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLASSIFICATION_OUTPUT_PATH" \
        --summary="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SUMMARY_OUTPUT_PATH" \
        --summary-machine="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SUMMARY_MACHINE_OUTPUT" \
        --importance="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$IMPORTANCE_OUTPUT" \
        --type-source="$TYPE_SOURCE" \
        --db-host="$POSTGRES_HOST" \
        --clear-existing
done
