#!/bin/sh

# name and version of docker image that will be created
DOCKER_IMAGE_NAME=distil_dev_postgres
DOCKER_IMAGE_VERSION=0.10.0

# datasets to ingest
DATASETS_SEED=(32_wikiqa 185_baseball 196_autoMpg 534_cps_85_wages 66_chlorineConcentration 22_handgeometry 1491_one_hundred_plants_margin 299_libras_move 56_sunspots LL1_726_TIDY_GPS_carpool_bus_service_rating_prediction)

# path to data on local system (ingest from HDFS not currently supported)
HOST_DATA_DIR=~/datasets/seed_datasets_current

# path to data on local system (ingest from HDFS not currently supported)
HOST_DATA_DIR_EVAL=~/datasets/seed_datasets_user_eval/Task1/
DATASETS_EVAL=(LL0_USER_EVAL_TASK1_1100_popularkids LL0_USER_EVAL_TASK1_acled)

DATASETS=(32_wikiqa 185_baseball 196_autoMpg 534_cps_85_wages 66_chlorineConcentration 22_handgeometry 1491_one_hundred_plants_margin 299_libras_move 56_sunspots LL0_USER_EVAL_TASK1_acled LL0_USER_EVAL_TASK1_1100_popularkids LL1_726_TIDY_GPS_carpool_bus_service_rating_prediction)

# path to data in the docker container
CONTAINER_DATA_DIR=/input/d3m

# path to data in the host with the copy of the original data
HOST_DATA_DIR_COPY=/input/d3m
