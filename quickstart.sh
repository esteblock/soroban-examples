#!/bin/bash

previewVersion="10"
quickstartTag="soroban-dev@sha256:ed57f7a7683e3568ae401f5c6e93341a9f77d8ad41191bf752944d7898981e0c"
 
set -e

case "$1" in
standalone)
    echo "Using standalone network"
    ARGS="--standalone"
    ;;
futurenet)
    echo "Using Futurenet network"
    ARGS="--futurenet"
    ;;
*)
    echo "Usage: $0 standalone|futurenet"
    exit 1
    ;;
esac

shift

echo "1. Creating docker soroban network"
(docker network inspect soroban-network -f '{{.Id}}' 2>/dev/null) \
  || docker network create soroban-network


echo "2. Running a soroban-precview docker container"

echo "Searching for a previous soroban-preview docker container"
containerID=$(docker ps --filter=`name=soroban-preview-${previewVersion}` --all --quiet)
if [[ ${containerID} ]]; then
    echo "Start removing soroban-preview-${previewVersion}  container."
    docker rm --force soroban-preview-${previewVersion}
    echo "Finished removing soroban-preview-${previewVersion} container."
else
    echo "No previous soroban-preview-${previewVersion} container was found"
fi

currentDir=$(pwd)
docker run -dti \
  --volume ${currentDir}:/workspace \
  --name soroban-preview-${previewVersion} \
  -p 8001:8000 \
  --ipc=host \
  --network soroban-network \
  esteblock/soroban-preview:${previewVersion}

# Run the stellar quickstart image
docker run --rm -ti \
  --name stellar \
  --network soroban-network \
  -p 8000:8000 \
  stellar/quickstart:${quickstartTag} \
  $ARGS \
  --enable-soroban-rpc \
  --protocol-version 20 \
  "$@" # Pass through args from the CLI
