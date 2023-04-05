#!/bin/sh
set -e

export PROJECT=$1
export ZONE=$2
export PREFIX=$3
export CLUSTERNAME=$4

# echo 'Destroying K8s Stale PVCs...'
# for pvc in $(gcloud compute disks list --project $PROJECT --filter="name:pvc*" --uri);do echo "Removing $pvc..."; gcloud compute disks delete $pvc --quiet; done
# sample metadata.json: {"clusterName":"gke-nm-r161rc4-us-west1-0","clusterID":"b7aa4680-e3af-4dc1-91e9-d8be12891a7f","infraID":"gke-nm-r161rc4-us-wes-24pq9","gcp":{"region":"us-west1","projectID":"nm-r161rc4-ylsw-0"}}

echo 'ssh into jumbox...'
echo "Project:$PROJECT"
echo "ZONE:$ZONE"
echo "PREFIX:$PREFIX"
echo "CLUSTERNAME:$CLUSTERNAME"
gcloud config set project $PROJECT
echo "Destroying Openshift cluster..."
gcloud compute ssh $PREFIX-0-jumpbox --zone=$ZONE --project $PROJECT --command "sudo /opt/ocp/files/openshift-install destroy cluster --dir $CLUSTERNAME/ --log-level debug"
# gcloud compute ssh $PREFIX-0-jumpbox --zone=$ZONE --project $PROJECT <<"EOL"
#     #!/bin/sh
# 	echo "Destroying Openshift cluster..."
#     echo "Project:$PROJECT"
#     echo "ZONE:$ZONE"
#     echo "PREFIX:$PREFIX"
#     echo "CLUSTERNAME:$CLUSTERNAME"
#     # echo "Deleting metadata..."
#     # sudo rm -rf /opt/ocp/files/$CLUSTERNAME/metadata.json
#     # echo "Recreating metadata..."
#     # sudo touch /opt/ocp/files/$CLUSTERNAME/metadata.json
#     # export CLUSTER_NAME=$CLUSTERNAME
#     # export REGION=REGION
#     # sudo /opt/ocp/files/openshift-install create ignition-configs --dir $CLUSTERNAME/ --log-level debug
#     # sudo echo '{\"clusterName\":\"${CLUSTER_NAME}\",\"clusterID\":\"\",\"infraID\":\"${CLUSTER_NAME}\",\"gcp\":{\"region\":\"${REGION}\",\"identifier\":[{\"kubernetes.io/cluster/${CLUSTER_NAME}\":\"owned\"}]}}' > /opt/ocp/files/$CLUSTERNAME/metadata.json
#     echo "Destroying $CLUSTERNAME..."
#     sudo /opt/ocp/files/openshift-install destroy cluster --dir $CLUSTERNAME/ --log-level debug
#     echo "Openshift cluster is being deleted..."
# EOL