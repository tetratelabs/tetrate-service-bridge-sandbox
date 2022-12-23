#!/usr/bin/env bash

set -e

eval "$(jq -r '@sh "TSB_VERSION=\(.tsb_version) REGISTRY=\(.registry)"')"

rm -rf /tmp/controlplane
helm pull tetrate-tsb-helm/controlplane --version "${TSB_VERSION}" --untar --untardir /tmp
REDIS_IMAGE=$(grep redis /tmp/controlplane/images.txt)
REDIS_IMAGE=${REDIS_IMAGE/containers.dl.tetrate.io/${REGISTRY}}

echo "{\"image\":\"${REDIS_IMAGE}\"}"
