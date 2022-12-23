#!/usr/bin/env bash

set -e

eval "$(jq -r '@sh "TSB_VERSION=\(.tsb_version) REGISTRY=\(.registry)"')"

TMP_DIR=$(mktemp -d)
helm pull tetrate-tsb-helm/controlplane --version "${TSB_VERSION}" --untar --untardir "${TMP_DIR}"
REDIS_IMAGE=$(grep redis "${TMP_DIR}/controlplane/images.txt")
REDIS_IMAGE=${REDIS_IMAGE/containers.dl.tetrate.io/${REGISTRY}}

echo "{\"image\":\"${REDIS_IMAGE}\"}"
