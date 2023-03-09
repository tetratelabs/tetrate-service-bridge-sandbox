#!/bin/sh

export PROJECT=$1

echo 'Destroying K8s Stale PVCs...'
for pvc in $(gcloud compute disks list --project $PROJECT --filter="name:pvc*" --uri);do echo "Removing $pvc..."; gcloud compute disks delete $pvc --quiet; done