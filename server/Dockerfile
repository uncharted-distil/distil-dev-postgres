# Set the base image to postgres alpine
FROM postgres:13-alpine

# Update postgres to use a new data folder.
RUN mkdir -p /usr/local/pgsql/data
RUN chown -R postgres:postgres /usr/local/pgsql/data
RUN chmod 700 /usr/local/pgsql/data

ENV PGDATA="/usr/local/pgsql/data"

ADD docker-entrypoint.sh /
ADD postgres-init.sh /
ADD init.sql /docker-entrypoint-initdb.d/
RUN /postgres-init.sh -p 5432:5432 -d postgres

# make sure package db is up to date
RUN apk update

# missing from baseline alpine
RUN apk add --no-cache ca-certificates
RUN apk update && apk add bash git make build-base
RUN apk add gdal gdal-dev

ARG DISTIL_BRANCH
RUN apk add --no-cache git make musl-dev go
ENV GOPROXY=direct
ENV GO111MODULE=on

RUN set -eux; \
        \
        apk add --no-cache --virtual .gosu-deps \
                ca-certificates \
                dpkg \
                gnupg \
        ; \
        \
        dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
        wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.12/gosu-$dpkgArch"; \
        wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.12/gosu-$dpkgArch.asc"; \
        \
# verify the signature
        export GNUPGHOME="$(mktemp -d)"; \
        gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
        gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
        command -v gpgconf && gpgconf --kill all || :; \
        rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
        \
# clean up fetch dependencies
        apk del --no-network .gosu-deps; \
        \
        chmod +x /usr/local/bin/gosu;

# copy in distil-ingest
RUN mkdir -p /distil-ingest
WORKDIR /distil-ingest
ADD config.sh .
ADD ingest.sh .
RUN env GOOS=linux GOARCH=amd64 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-ingest@$DISTIL_BRANCH
RUN cp ~/go/bin/distil-ingest ./distil-ingest

# copy in d3m test data
RUN mkdir -p /input
COPY data /input

# start postgres and run ingest
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/e1f115e4ca285c3c24e847c4dd4be955e0ed51c2/wait-for-it.sh /
RUN chmod 777 /wait-for-it.sh
RUN /docker-entrypoint.sh postgres & \
  sleep 60; /distil-ingest/ingest.sh

# remove ingest related files
WORKDIR /
RUN rm -r -f /distil-ingest && rm /wait-for-it.sh && rm -r -f /input

# expose standard ports
EXPOSE 5432

USER postgres
