#!/usr/bin/env bash

docker build -t image-fetcher hack/image-fetcher

# test image on a private repo
echo docker.io/katnip/ukraine-arrival-support-fe:latest > images.txt

docker run --rm -i --privileged \
-e DOCKER_USER=${DOCKER_USER} \
-e DOCKER_PASSWORD=${DOCKER_PASSWORD} \
image-fetcher < images.txt > test_image.tar || { \
    code=$? && rm -f -- test_image.tar && exit $code ; \
}
rm images.txt
