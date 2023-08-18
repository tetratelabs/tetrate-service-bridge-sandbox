#!/usr/bin/env bash

set -e

eval "$(jq -r '@sh "TSB_VERSION=\(.tsb_version) CACHED_BY=\(.cached_by)"')"

# If a cached value was requested and is present, just return it
if [[ -f "${CACHED_BY}" ]]; then
    cat "${CACHED_BY}"
    exit 0
fi

if [[ "${TSB_VERSION}" =~ .*"-dev" ]]; then
    TSB_GCR_INTERNAL_REGISTRY="gcr.io/tetrate-internal-containers"
    TSB_GCR_INTERNAL_TOKEN=$(gcloud auth print-access-token)
    OUT="{\"token\":\"${TSB_GCR_INTERNAL_TOKEN}\",\"registry\":\"${TSB_GCR_INTERNAL_REGISTRY}\"}"
else
    OUT="{\"token\":\"\",\"registry\":\"\"}"
fi

if [[ -n "${CACHED_BY}" ]]; then
    echo "${OUT}" | tee "${CACHED_BY}"
else
    echo "${OUT}"
fi
