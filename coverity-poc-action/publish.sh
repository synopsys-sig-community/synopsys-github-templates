#!/bin/sh -x
. env.sh
export CR_PAT=$GITHUB_TOKEN
echo $CR_PAT | docker login ghcr.io -u jcroall --password-stdin
docker tag $IMAGE_NAME:$VERSION ghcr.io/$OWNER/$IMAGE_NAME:$VERSION
docker push ghcr.io/$OWNER/$IMAGE_NAME:$VERSION
