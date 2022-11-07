#!/usr/bin/env bash

set -e

VERSION=$(jq -r '.tsb_version')

if [[ "${VERSION}" =~ .*"-dev" ]]; then
    REGISTRY="gcr.io/tetrate-internal-containers"
    TOKEN=$(gcloud auth print-access-token)
fi

echo "{\"token\": \"${TOKEN}\",\"registry\":\"${REGISTRY}\"}"
