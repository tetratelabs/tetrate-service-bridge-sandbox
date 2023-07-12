#!/bin/bash

HELMCHART_SOURCE_DIR=$1

if [ ! -d "$HELMCHART_SOURCE_DIR" ]; then
 echo "Directory $HELMCHART_SOURCE_DIR DOES NOT exist.";
 exit;
fi

helm package $HELMCHART_SOURCE_DIR -d ../charts/

helm repo index --url https://tetrateio.github.io/tetrate-service-bridge-sandbox/helm/ ../

mv ../index.yaml ../../