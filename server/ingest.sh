#!/bin/bash

source ./config.sh

echo "**************"
echo $DATA_DIR
echo $DATASETS

SCHEMA_PATH=/data/dataSchema.json
TRAINING_DATA_PATH=/data/trainData.csv
TRAINING_TARGETS_PATH=/data/trainTargets.csv
RAW_DATA=/data/raw_data
MERGED_OUTPUT_PATH=/data/merged.csv
OUTPUT_SCHEMA=/data/mergedDataSchema.json
MERGE_HAS_HEADER=1


for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Merging $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-merge \
        --schema="$CONTAINER_DATA_DIR/$DATASET/$SCHEMA_PATH" \
        --training-data="$CONTAINER_DATA_DIR/$DATASET/$TRAINING_DATA_PATH" \
        --training-targets="$CONTAINER_DATA_DIR/$DATASET/$TRAINING_TARGETS_PATH" \
        --raw-data="$CONTAINER_DATA_DIR/$DATASET/$RAW_DATA" \
        --output-path="$CONTAINER_DATA_DIR/$DATASET/$MERGED_OUTPUT_PATH" \
        --output-schema-path="$CONTAINER_DATA_DIR/$DATASET/$OUTPUT_SCHEMA" \
        --has-header=$MERGE_HAS_HEADER \
        --include-raw-dataset
done

CLASSIFICATION_OUTPUT_PATH=/data/classification.json
REST_ENDPOINT=http://localhost:5000
CLASSIFICATION_FUNCTION=fileUpload

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Classifying $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-classify \
        --schema="$CONTAINER_DATA_DIR/$DATASET/$OUTPUT_SCHEMA" \
        --rest-endpoint="$REST_ENDPOINT" \
        --classification-function="$CLASSIFICATION_FUNCTION" \
        --dataset="$CONTAINER_DATA_DIR/$DATASET/$MERGED_OUTPUT_PATH" \
        --output="$CONTAINER_DATA_DIR/$DATASET/$CLASSIFICATION_OUTPUT_PATH" \
        --include-raw-dataset
done

IMPORTANCE_OUTPUT=/data/importance.json
RANKING_REST_ENDPOINT=HTTP://localhost:5001
RANKING_FUNCTION=pca
NUMERIC_OUTPUT_SUFFIX=_numeric.csv
TYPE_SOURCE=classification

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Ranking $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-rank \
        --schema="$CONTAINER_DATA_DIR/$DATASET/$OUTPUT_SCHEMA" \
        --dataset="$CONTAINER_DATA_DIR/$DATASET/$MERGED_OUTPUT_PATH" \
        --rest-endpoint="$RANKING_REST_ENDPOINT" \
        --ranking-function="$RANKING_FUNCTION" \
        --numeric-output="$CONTAINER_DATA_DIR/$DATASET/$DATASET_DATA_DIR/$DATASET$NUMERIC_OUTPUT_SUFFIX" \
        --classification="$CONTAINER_DATA_DIR/$DATASET/$CLASSIFICATION_OUTPUT_PATH" \
        --has-header=$MERGE_HAS_HEADER \
        --output="$CONTAINER_DATA_DIR/$DATASET/$IMPORTANCE_OUTPUT" \
        --type-source="$TYPE_SOURCE" \
        --include-raw-dataset
done

METADATA_INDEX=datasets
ES_ENDPOINT=http://localhost:9200
SUMMARY_OUTPUT_PATH=summary.txt
TYPE_SOURCE=classification

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Ingesting $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-ingest \
        --database=distil \
        --db-table="$DATASET" \
        --db-user=distil \
        --db-password=gopher! \
        --schema="$CONTAINER_DATA_DIR/$DATASET/$OUTPUT_SCHEMA" \
        --dataset="$CONTAINER_DATA_DIR/$DATASET/$MERGED_OUTPUT_PATH" \
        --classification="$CONTAINER_DATA_DIR/$DATASET/$CLASSIFICATION_OUTPUT_PATH" \
        --summary="$CONTAINER_DATA_DIR/$DATASET/$SUMMARY_OUTPUT_PATH" \
        --importance="$CONTAINER_DATA_DIR/$DATASET/$IMPORTANCE_OUTPUT" \
        --type-source="$TYPE_SOURCE" \
        --clear-existing \
        --include-raw-dataset
done
