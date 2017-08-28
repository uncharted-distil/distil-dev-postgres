#!/bin/bash

source ./config.sh

echo "**************"
echo $DATA_DIR
echo $DATASETS

for dataset in "${DATASETS[@]}"
do
    ds=${dataset/_}
    ./distil-ingest -database=distil -db-table $ds -db-user=distil -db-password=gopher! -dataset=/input/$dataset/data/merged.csv -schema=/input/$dataset/data/dataSchema.json -classification=/input/$dataset/data/classification_dn.json -clear-existing=false
done
