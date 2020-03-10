#!/bin/bash
set -euxo pipefail

NO_CACHE=""
export DOCKER_BUILDKIT=0
BASE_CONTAINER="saagie/jupyter-python-nbk:v2"

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

docker build $NO_CACHE --build-arg BASE_CONTAINER=$BASE_CONTAINER -t $TYPE .
