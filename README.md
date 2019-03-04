# distil-dev-postgres

Provides a dockerfile and supporting scripts to generate images containing Postgres.  The image build step uses [distil-ingest](https://github.com/uncharted-distil/distil-ingest) to build a [distil](https://github.com/uncharted-distil/distil)-ready index from source data; this index is saved as part of the image, allowing for generation of drop-in test container that can be run locally.

## Dependencies

- [Go](https://golang.org/) version 1.6+ with the `GOPATH` environment variable specified and `$GOPATH/bin` in your `PATH`.
- [Docker](http://www.docker.com/)

## Building an Image

1. Edit the docker image name and version, as well as the ingest data source info in `./server/config.sh`.  Data must be stored locally - HDFS storage is not yet supported.
2. Run `./build.sh` to build the image.

## Deploying the Container

A container based on the image can be deployed using the provided `./run.sh` script, or a command based on the contents of that script.

## Customization

`./server/config.sh` contains parameters for modifying the input dataset list.  The datasets must be stored in the location specified by `DATA_DIR` as sub-folders in the D3M format.  The `DATASETS` variable needs to be set to indicate the sub-directories to be included in the ingest.
