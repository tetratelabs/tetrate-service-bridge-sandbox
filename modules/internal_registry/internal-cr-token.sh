#!/usr/bin/env bash

set -e

TSB_VERSION=$(jq -r '.tsb_version')

if [[ "${TSB_VERSION}" =~ .*"-dev" ]]; then
    TSB_GCR_INTERNAL_REGISTRY="gcr.io/tetrate-internal-containers"
    TSB_GCR_INTERNAL_TOKEN=$(gcloud auth print-access-token)
    echo "{\"token\":\"${TSB_GCR_INTERNAL_TOKEN}\",\"registry\":\"${TSB_GCR_INTERNAL_REGISTRY}\"}"
else
    echo "{\"token\":\"\",\"registry\":\"\"}"
fi
