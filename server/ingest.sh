#!/bin/bash

source ./config.sh

echo "**************"
echo $DATA_DIR
echo $DATASETS

SCHEMA_PATH=/data/dataSchema.json
TRAINING_DATA_PATH=/data/trainData.csv
TRAINING_TARGETS_PATH=/data/trainTargets.csv
MERGED_OUTPUT_PATH=/data/merged.csv

AWS_S3_HOST=https://s3.amazonaws.com/
AWS_S3_BUCKET=d3m-data
AWS_S3_KEY_PREFIX=merged_o_data
AWS_S3_KEY_SUFFIX=_merged.csv

MERGE_HAS_HEADER=1
MERGE_INCLUDE_HEADER=0


for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Merging $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-merge \
        --schema="$CONTAINER_DATA_DIR/$DATASET/$SCHEMA_PATH" \
        --training-data="$CONTAINER_DATA_DIR/$DATASET/$TRAINING_DATA_PATH" \
        --training-targets="$CONTAINER_DATA_DIR/$DATASET/$TRAINING_TARGETS_PATH" \
        --output-bucket="$AWS_S3_BUCKET" \
        --output-key="$AWS_S3_KEY_PREFIX/$DATASET$AWS_S3_KEY_SUFFIX" \
        --output-path="$CONTAINER_DATA_DIR/$DATASET/$MERGED_OUTPUT_PATH" \
        --has-header=$MERGE_HAS_HEADER \
        --include-header=$MERGE_INCLUDE_HEADER
done

CLASSIFICATION_OUTPUT_PATH=/data/classification.json
CLASSIFICATION_KAFKA_ENDPOINT=10.108.4.41:9092

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Classifying $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-classify \
        --schema="$CONTAINER_DATA_DIR/$DATASET/$SCHEMA_PATH" \
        --kafka-endpoints="$CLASSIFICATION_KAFKA_ENDPOINT" \
        --dataset="$AWS_S3_HOST/$AWS_S3_BUCKET/$AWS_S3_KEY_PREFIX/$DATASET$AWS_S3_KEY_SUFFIX" \
        --output="$CONTAINER_DATA_DIR/$DATASET/$CLASSIFICATION_OUTPUT_PATH"
done

AWS_RANK_OUTPUT_BUCKET=d3m-data
AWS_RANK_OUTPUT_KEY_PREFIX=numeric_o_data
AWS_RANK_OUTPUT_KEY_SUFFIX=_numeric.csv
RANKING_KAFKA_ENDPOINT=10.108.4.41:9092
IMPORTANCE_OUTPUT=/data/importance.json

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Ranking $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-rank \
        --schema="$CONTAINER_DATA_DIR/$DATASET/$SCHEMA_PATH" \
        --dataset="$CONTAINER_DATA_DIR/$DATASET/$MERGED_OUTPUT_PATH" \
        --classification="$CONTAINER_DATA_DIR/$DATASET/$CLASSIFICATION_OUTPUT_PATH" \
        --output-bucket="$AWS_RANK_OUTPUT_BUCKET" \
        --output-key="$AWS_RANK_OUTPUT_KEY_PREFIX/$DATASET$AWS_RANK_OUTPUT_KEY_SUFFIX" \
        --has-header=$MERGE_HAS_HEADER \
        --include-header=$MERGE_INCLUDE_HEADER \
        --kafka-endpoints="$RANKING_KAFKA_ENDPOINT" \
        --output="$CONTAINER_DATA_DIR/$DATASET/$IMPORTANCE_OUTPUT"
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
        --schema="$CONTAINER_DATA_DIR/$DATASET/$SCHEMA_PATH" \
        --dataset="$CONTAINER_DATA_DIR/$DATASET/$MERGED_OUTPUT_PATH" \
        --classification="$CONTAINER_DATA_DIR/$DATASET/$CLASSIFICATION_OUTPUT_PATH" \
        --summary="$CONTAINER_DATA_DIR/$DATASET/$SUMMARY_OUTPUT_PATH" \
        --importance="$CONTAINER_DATA_DIR/$DATASET/$IMPORTANCE_OUTPUT" \
        --type-source="$TYPE_SOURCE" \
        --clear-existing
done
