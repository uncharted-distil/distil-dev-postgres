# Set the base image to postgres alpine
FROM docker-hub.uncharted.software/postgres:12-alpine

# Update postgres to use a new data folder.
RUN mkdir -p /usr/local/pgsql/data
RUN chown -R postgres:postgres /usr/local/pgsql/data
RUN chmod 700 /usr/local/pgsql/data

ENV PGDATA="/usr/local/pgsql/data"

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

ENV POSTGIS_VERSION 3.0.0
ENV POSTGIS_SHA256 1c83fb2fc8870d36ed49859c49a12c8c4c8ae8c5c3f912a21a951c5bcc249123
RUN set -ex \
    \
    && apk add --no-cache --virtual .fetch-deps ca-certificates openssl tar \
    \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/$POSTGIS_VERSION.tar.gz" \
    && echo "$POSTGIS_SHA256 *postgis.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        autoconf automake json-c-dev libtool libxml2-dev make perl llvm clang clang-dev \
    \
    && apk add --no-cache --virtual .build-deps-edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        g++ gdal-dev geos-dev proj-dev protobuf-c-dev \
    && cd /usr/src/postgis \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && apk add --no-cache --virtual .postgis-rundeps-edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        geos gdal proj protobuf-c libstdc++ \
    && cd / \
    && rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps .build-deps-edge

COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
COPY ./update-postgis.sh /usr/local/bin

ADD docker-entrypoint.sh /
ADD postgres-init.sh /
ADD init.sql /docker-entrypoint-initdb.d/
RUN /postgres-init.sh -p 5432:5432 -d postgres

# copy in distil-ingest
RUN mkdir -p /distil-ingest
WORKDIR /distil-ingest
ADD config.sh .
ADD ingest.sh .
RUN env GOOS=linux GOARCH=amd64 go get -a -v github.com/uncharted-distil/distil-ingest/cmd/distil-ingest@$DISTIL_BRANCH
RUN cp ~/go/bin/distil-ingest ./distil-ingest

# copy in d3m test data
RUN mkdir -p /tmp/d3m
COPY data /tmp/d3m

# start postgres and run ingest
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/e1f115e4ca285c3c24e847c4dd4be955e0ed51c2/wait-for-it.sh /
RUN chmod 777 /wait-for-it.sh
RUN /docker-entrypoint.sh postgres & \
  sleep 60; /distil-ingest/ingest.sh

# remove ingest related files
WORKDIR /
RUN rm -r -f /distil-ingest && rm /wait-for-it.sh && rm -r -f /input && rm -r -f /tmp/d3m
RUN apk del gdal-dev gdal go
RUN rm -rf /root

# expose standard ports
EXPOSE 5432

USER postgres
