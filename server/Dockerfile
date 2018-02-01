# Set the base image to postgres alpine
FROM postgres:10-alpine

ARG smmry_key

ENV SMMRY_API_KEY=$smmry_key

# Update postgres to use a new data folder.
RUN mkdir -p /usr/local/pgsql/data
RUN chown -R postgres:postgres /usr/local/pgsql/data
RUN chmod 700 /usr/local/pgsql/data

ENV PGDATA="/usr/local/pgsql/data"

ADD postgres-init.sh /
ADD init.sql /docker-entrypoint-initdb.d/
RUN /postgres-init.sh -p 5432:5432 -d postgres

# make sure package db is up to date
RUN apk update

# missing from baseline alpine
RUN apk add --no-cache ca-certificates

# copy in distil-ingest
RUN mkdir -p /distil-ingest
WORKDIR /distil-ingest
ADD config.sh .
ADD distil-ingest .
ADD distil-merge .
ADD distil-rank .
ADD distil-classify .
ADD distil-summary .
ADD ingest.sh .

# copy in d3m test data
RUN mkdir -p /input
ADD data /input

# start postgres and run ingest
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/e1f115e4ca285c3c24e847c4dd4be955e0ed51c2/wait-for-it.sh /
RUN /docker-entrypoint.sh postgres & \
  /bin/bash /wait-for-it.sh -t 0 localhost:5432 -- psql -U postgres -f /docker-entrypoint-initdb.d/init.sql; \
  /distil-ingest/ingest.sh; \
  exit 0;

# remove ingest related files
WORKDIR /
RUN rm -r -f /distil-ingest; \
  rm /wait-for-it.sh; \
  rm -r -f /input;

# expose standard ports
EXPOSE 5432

USER postgres
