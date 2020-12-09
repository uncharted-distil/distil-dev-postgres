#!/bin/bash

source ./config.sh

FINAL_OUTPUT_PATH=dataset_TRAIN/tables/learningData.csv
OUTPUT_SCHEMA=dataset_TRAIN/datasetDoc.json
CLASSIFICATION_OUTPUT_PATH=classification.json
IMPORTANCE_OUTPUT=importance.json
SUMMARY_MACHINE_OUTPUT=summary-machine.json
METADATA_INDEX=datasets
POSTGRES_HOST=127.0.0.1
SUMMARY_OUTPUT_PATH=summary.txt

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
        --schema="$CONTAINER_DATA_DIR/${DATASET}/$OUTPUT_SCHEMA" \
        --dataset="$CONTAINER_DATA_DIR/${DATASET}/$FINAL_OUTPUT_PATH" \
        --classification="$CLASSIFICATION_OUTPUT_PATH" \
        --summary="$SUMMARY_OUTPUT_PATH" \
        --summary-machine="$SUMMARY_MACHINE_OUTPUT" \
        --importance="$IMPORTANCE_OUTPUT" \
        --db-host="$POSTGRES_HOST"
done
