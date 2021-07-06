tctl install manifest control-plane-secrets \
    --elastic-password $ES_PASSWORD \
    --elastic-username elastic \
    --elastic-ca-certificate $ES_CACERT \
    --cluster $CLUSTER_NAME \
    --controlplane istio-system \
    --xcp-certs "$(tctl install cluster-certs --cluster $CLUSTER_NAME)" > controlplane-secrets.yaml