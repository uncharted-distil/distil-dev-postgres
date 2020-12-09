#!/bin/bash

sleep 180
set -e

# Perform all actions as $POSTGRES_USER
export PGUSER=distil
# Create the 'template_postgis' template db
"${psql[@]}" <<- 'EOSQL'
CREATE DATABASE template_postgis IS_TEMPLATE true;
EOSQL
# Load PostGIS into both template_database and $POSTGRES_DB
echo "okay"
echo "${psql[@]}"
for DB in template_postgis distil; do
	echo "Loading PostGIS extensions into $DB"
	"${psql[@]} --dbname=$DB" <<-'EOSQL'
		CREATE EXTENSION IF NOT EXISTS postgis;
		CREATE EXTENSION IF NOT EXISTS postgis_topology;
		CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
		CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
	EOSQL
	echo "HERE"
done
