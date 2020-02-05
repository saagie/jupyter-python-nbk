#!/bin/bash
set -euxo pipefail

NO_CACHE=""
export DOCKER_BUILDKIT=0
BASE_CONTAINER="jupyter/scipy-notebook:c7fb6660d096"
PYTHON2_IMG="ypetit/test:python-2.7"
PYTHON3_IMG="ypetit/test:python-3.6"


while (( $# )); do
    case $1 in
        --no-cache) NO_CACHE="--no-cache"
        ;;
        --buildkit) export DOCKER_BUILDKIT=1
        ;;
        --*) echo "Bad Option $1"
        ;;
        *) TYPE=$1
        ;;
        *) break
	;;
    esac
    shift
done

docker build \
    --build-arg BASE_CONTAINER=$BASE_CONTAINER \
    --build-arg PYTHON2_IMG=$PYTHON2_IMG \
    --build-arg PYTHON3_IMG=$PYTHON3_IMG \
    -t $TYPE \
    .
