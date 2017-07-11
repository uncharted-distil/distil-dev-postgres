# Set the base image to postgres alpine
FROM postgres:10-alpine

ADD init.sql /docker-entrypoint-initdb.d/

# make sure package db is up to date
RUN apk update

# missing from baseline alpine
RUN apk add --no-cache ca-certificates

# download build toolchain
RUN apk add --no-cache --virtual .build-deps \
  gcc \
  linux-headers \
  make \
  musl-dev \
  tar

# copy in distil-ingest
RUN mkdir -p /distil-ingest
WORKDIR /distil-ingest
ADD config.sh .
ADD distil-ingest .
ADD ingest.sh .

# copy in d3m test data
RUN mkdir -p /input
ADD data /input

# start postgres and run ingest
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/e1f115e4ca285c3c24e847c4dd4be955e0ed51c2/wait-for-it.sh /
RUN /docker-entrypoint.sh postgres -p /tmp/epid & \
  /bin/bash /wait-for-it.sh -t 0 localhost:5432 -- psql -U postgres -f /docker-entrypoint-initdb.d/init.sql; \
  /distil-ingest/ingest.sh; \
  kill $(cat /tmp/epid) && wait $(cat /tmp/epid); \
  exit 0;

# remove ingest related files
WORKDIR /
RUN rm -r -f /distil-ingest; \
  rm /wait-for-it.sh; \
  rm -r -f /input;

# copy run script across
ADD start_services.sh /

# expose standard ports
EXPOSE 5432

CMD . /start_services.sh
