#!/bin/sh -x
. env.sh
docker build -t coverity-poc-action . --tag $IMAGE_NAME:$VERSION
