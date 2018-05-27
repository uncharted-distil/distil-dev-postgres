#!/bin/bash

source ./config.sh

echo "**************"
echo $DATA_DIR
echo $DATASETS

SCHEMA=/datasetDoc.json
OUTPUT_PATH=features/
DATASET_FOLDER_SUFFIX=_dataset
HAS_HEADER=1
FEATURIZE_FUNCTION=fileupload
REST_ENDPOINT=HTTP://10.108.4.42:5002
DATA_SERVER=HTTP://10.108.4.104

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Featurizing $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    go run cmd/distil-featurize/main.go \
        --rest-endpoint="$REST_ENDPOINT" \
        --featurize-function="$FEATURIZE_FUNCTION" \
        --dataset="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN" \
        --media-path="$DATA_SERVER/${DATASET}" \
        --schema="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
        --output="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN" \
        --has-header=$HAS_HEADER
done

DATA_PATH=/features/features.csv
MERGED_OUTPUT_PATH=tables/merged.csv
MERGED_OUTPUT_HEADER_PATH=tables/mergedHeader.csv
OUTPUT_SCHEMA=mergedDatasetDoc.json
MERGE_HAS_HEADER=1

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Merging $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-merge \
        --schema="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SCHEMA" \
        --data="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$DATA_PATH" \
        --raw-data="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/" \
        --output-path="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_PATH" \
        --output-path-relative="$MERGED_OUTPUT_PATH" \
        --output-path-header="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_HEADER_PATH" \
        --output-schema-path="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$OUTPUT_SCHEMA" \
        --has-header=$MERGE_HAS_HEADER
done

CLASSIFICATION_OUTPUT_PATH=classification.json
REST_ENDPOINT=http://localhost:5000
CLASSIFICATION_FUNCTION=fileUpload

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Classifying $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-classify \
        --rest-endpoint="$REST_ENDPOINT" \
        --classification-function="$CLASSIFICATION_FUNCTION" \
        --dataset="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_PATH" \
        --output="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLASSIFICATION_OUTPUT_PATH"
done

IMPORTANCE_OUTPUT=importance.json
RANKING_REST_ENDPOINT=HTTP://localhost:5001
RANKING_FUNCTION=pca
NUMERIC_OUTPUT_SUFFIX=_numeric.csv
TYPE_SOURCE=classification
ROW_LIMIT=1000

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Ranking $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-rank \
        --schema="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$OUTPUT_SCHEMA" \
        --dataset="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_PATH" \
        --rest-endpoint="$RANKING_REST_ENDPOINT" \
        --ranking-function="$RANKING_FUNCTION" \
        --ranking-output="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$DATASET$NUMERIC_OUTPUT_SUFFIX" \
        --classification="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLASSIFICATION_OUTPUT_PATH" \
        --has-header=$HAS_HEADER \
        --row-limit=$ROW_LIMIT \
        --output="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$IMPORTANCE_OUTPUT" \
        --type-source="$TYPE_SOURCE"
done

SUMMARY_MACHINE_OUTPUT=summary-machine.json
SUMMARY_REST_ENDPOINT=HTTP://10.108.4.42:5003
SUMMARY_FUNCTION=fileUpload

for DATASET in "${DATASETS[@]}"
do
    echo "--------------------------------------------------------------------------------"
    echo " Summarizing $DATASET dataset"
    echo "--------------------------------------------------------------------------------"
    ./distil-summary \
        --rest-endpoint="$SUMMARY_REST_ENDPOINT" \
        --summary-function="$SUMMARY_FUNCTION" \
        --dataset="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_HEADER_PATH" \
        --output="$DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SUMMARY_MACHINE_OUTPUT"
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
        --db-table="d_$DATASET" \
        --db-user=distil \
        --db-password=gopher! \
        --schema="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$OUTPUT_SCHEMA" \
        --dataset="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$MERGED_OUTPUT_PATH" \
        --classification="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$CLASSIFICATION_OUTPUT_PATH" \
        --summary="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SUMMARY_OUTPUT_PATH" \
        --summary-machine="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$SUMMARY_MACHINE_OUTPUT" \
        --importance="$CONTAINER_DATA_DIR/${DATASET}/TRAIN/dataset_TRAIN/$IMPORTANCE_OUTPUT" \
        --type-source="$TYPE_SOURCE" \
        --clear-existing
done
