#!/bin/sh

# name and version of docker image that will be created
DOCKER_IMAGE_NAME=distil_dev_postgres
DOCKER_IMAGE_VERSION=0.3

# datasets to ingest
DATASETS=(o_185 o_196 o_313 o_38 o_4550)

# path to data on local system (ingest from HDFS not currently supported)
DATA_PATH=~/data/d3m

# unset input compression - switch to gzip as required
INPUT_COMPRESSION=
