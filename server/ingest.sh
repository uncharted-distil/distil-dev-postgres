#!/bin/bash

source ./config.sh

echo "**************"
echo $DATA_DIR
echo $DATASETS

for dataset in "${DATASETS[@]}"
do
    ./distil-ingest -database=distil -db-table $dataset -db-user=distil -db-password=gopher!! -clear-existing -dataset-path /input/$dataset
done
