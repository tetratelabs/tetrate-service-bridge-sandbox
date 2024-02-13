# Canary Upgrades

## Summary

This walkthrough completes a `Control Plane` upgrade and takes a phased approach to upgrade the `Data Plane`. This is achieved by creating a new revision of the Isolation Boundary and updating the namespace to use the new revision.

- [Revisioned Upgrade KB](https://docs.tetrate.io/service-bridge/setup/upgrades/revisioned-to-revisioned)

## Pre-requisites

- Ensure that the Management Plane is upgraded to the Target Version.
- Ensure that `tctl install image-sync` is completed for the Target Version.
- Run `make argocd` and ensure that the bookinfo application is deployed
- The `yq` tool is installed (used to update yaml files)
- An alias `kip` will be used for validation: `alias kip="kubectl get pods -o=custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[*].image'"_**`

## Upgrade Control Plane

The following steps are performed to upgrade the Control Plane

### Set Environment Variables

```sh
CLUSTER_NAME="aks-sw02-eastus-1"
CURRENT_VERSION="1.8.0-internal-rc3"
UPGRADE_VERSION="1.8.0"

```

### Upgrade Control Plane

```sh

# Delete the bookinfo argocd application so the namespace doesn't reconcile
k delete applications.argoproj.io bookinfo -n argocd   

# Obtain Helm values used for installation
helm get values controlplane -n istio-system -o yaml > $CLUSTER_NAME-cp.yaml

# Update the version configured in Helm values
yq eval-all '.image.tag = "'${UPGRADE_VERSION}'"' $CLUSTER_NAME-cp.yaml -i

# Upgrade Control Plane
helm upgrade controlplane -n istio-system -f $CLUSTER_NAME-cp.yaml tetrate-tsb-helm/controlplane --version $UPGRADE_VERSION
```

### Verify Control Plane Upgrade

Should see most components using new versions, the only components not upgraded would be the `istiod`` dataplane/controlplane components.

```sh
kip -n istio-system

NAME                                                     IMAGE
edge-6dc4ff6ff4-7fjhw                                    sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/xcpd:v1.8.1
istio-operator-76b798c8d7-kkjhm                          sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/operator:1.19.3-9d7a73d4d6-distroless
istio-operator-canary-6c4447c878-mrzx7                   sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/operator:1.19.3-9d7a73d4d6-distroless
istio-system-custom-metrics-apiserver-6647dbd89f-d775k   sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/swck:976d7b6
istiod-558bbb6db4-rtljl                                  sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/pilot:1.19.3-9d7a73d4d6-distroless
istiod-canary-85d46f9f5d-lnxdl                           sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/pilot:1.19.3-9d7a73d4d6-distroless
oap-deployment-66df8bc595-9b2d4                          sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/proxyv2:1.19.3-9d7a73d4d6-distroless,sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/spm-user:fd0086c4263c33dfcf2d2c6cafefc3827f65c9a2,sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/proxyv2:1.19.5-f764c5d759-distroless
onboarding-operator-d4bf7bb4b-ffsrw                      sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/onboarding-operator-server:1.8.0
otel-collector-86f8f7fc4c-tw2zq                          sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/otelcol:0.89.0,sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/proxyv2:1.19.5-f764c5d759-distroless
ratelimit-server-5b5c48bf55-n47ww                        sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/ratelimit:5e1be594-tetrate-v1
tsb-operator-control-plane-864c9bd5fc-m6rj4              sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/tsboperator-server:1.8.0
vmgateway-f9bfddc45-9fw7j                                sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/proxyv2:1.19.3-9d7a73d4d6-distroless
wasmfetcher-8fc9b9f45-drs4l                              sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/wasmfetcher-server:1.8.0
xcp-operator-edge-6c4984b5d4-dj4xk                       sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/xcp-operator:v1.8.1
```

### Add New `tsbVersion` for revision: `canary`


```sh
# Update canary revision to be new version
yq eval-all '.spec.components.xcp.isolationBoundaries[0].revisions |= map(select(.name = "canary").istio.tsbVersion = "'${UPGRADE_VERSION}'")' $CLUSTER_NAME-cp.yaml -i

# Upgrade Control Plane
helm upgrade controlplane -n istio-system -f $CLUSTER_NAME-cp.yaml tetrate-tsb-helm/controlplane --version $UPGRADE_VERSION
```

### Verify istiod versions updated

```sh
kip -n istio-system -l app=istiod
NAME                             IMAGE
istiod-558bbb6db4-rtljl          sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/pilot:1.19.3-9d7a73d4d6-distroless
istiod-canary-7f7576f989-q8f8q   sw021tsbacrqaxhebu5d5uuq0kr.azurecr.io/pilot:1.19.5-f764c5d759-distroless

```

## Dataplane Upgrade

The phased approach will now be taken to upgrade the `Data Plane`.

### Verify Application Current Version

Application shouldn't have rebooted afer upgrade of the control plane and should still be using the previous version of the istiod `proxyv2` which we can see below.

```sh
kubectl get pod -n bookinfo
NAME                            READY   STATUS    RESTARTS   AGE
app-gw-6d6f4b5f58-jm885         1/1     Running   0          138m
details-v1-7dc5dc86fc-ck58j     2/2     Running   0          139m
details-v2-996c79dfc-2jjrz      2/2     Running   0          139m
productpage-v1-db7b8567-8m9b4   2/2     Running   0          139m
ratings-v1-798f8bbb66-n8mhm     2/2     Running   0          139m
reviews-v1-6855499658-6s7gx     2/2     Running   0          139m
reviews-v2-5bf46f8fb6-ts2w9     2/2     Running   0          139m
reviews-v3-5868dd8d98-8vz5k     2/2     Running   0          139m
```

Verify with `kip` alias

```sh
kip -n bookinfo
NAME                            IMAGE
app-gw-6d6f4b5f58-jm885         us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.3-9d7a73d4d6-distroless
details-v1-7dc5dc86fc-ck58j     us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.3-9d7a73d4d6-distroless,docker.io/istio/examples-bookinfo-details-v1:1.16.4
details-v2-996c79dfc-2jjrz      us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.3-9d7a73d4d6-distroless,docker.io/istio/examples-bookinfo-details-v2:1.18.0
productpage-v1-db7b8567-8m9b4   us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.3-9d7a73d4d6-distroless,docker.io/istio/examples-bookinfo-productpage-v1:1.16.4
ratings-v1-798f8bbb66-n8mhm     us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.3-9d7a73d4d6-distroless,docker.io/istio/examples-bookinfo-ratings-v1:1.16.4
reviews-v1-6855499658-6s7gx     us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.3-9d7a73d4d6-distroless,docker.io/istio/examples-bookinfo-reviews-v1:1.16.4
reviews-v2-5bf46f8fb6-ts2w9     us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.3-9d7a73d4d6-distroless,docker.io/istio/examples-bookinfo-reviews-v2:1.16.4
reviews-v3-5868dd8d98-8vz5k     us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.3-9d7a73d4d6-distroless,docker.io/istio/examples-bookinfo-reviews-v3:1.16.4
```

### Update Application Namespace to use New Revision
```sh
kubectl label ns bookinfo istio-injection-
kubectl label ns bookinfo istio.io/rev=canary
kubectl rollout restart deployment -n bookinfo
```

### Validate Application is using New Revision
New version of `proxyv2` is now being used by application once the pods are restarted.

```sh
kip -n bookinfo
NAME                              IMAGE
app-gw-7c5499cff9-q6825           us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.5-f764c5d759-distroless
details-v1-5bf49d95-qhzwg         us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.5-f764c5d759-distroless,docker.io/istio/examples-bookinfo-details-v1:1.16.4
details-v2-7bd47ff55c-769v7       us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.5-f764c5d759-distroless,docker.io/istio/examples-bookinfo-details-v2:1.18.0
productpage-v1-5b59b54d5b-qmlvb   us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.5-f764c5d759-distroless,docker.io/istio/examples-bookinfo-productpage-v1:1.16.4
ratings-v1-5cb5bcf464-qqdlt       us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.3-9d7a73d4d6-distroless,docker.io/istio/examples-bookinfo-ratings-v1:1.16.4
ratings-v1-5cb5bcf464-rgdss       us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.5-f764c5d759-distroless,docker.io/istio/examples-bookinfo-ratings-v1:1.16.4
reviews-v1-7c9d9f894-929gl        us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.5-f764c5d759-distroless,docker.io/istio/examples-bookinfo-reviews-v1:1.16.4
reviews-v2-b5d5578d-vzf2s         us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.5-f764c5d759-distroless,docker.io/istio/examples-bookinfo-reviews-v2:1.16.4
reviews-v3-5c994464db-4rvcl       us-west1-docker.pkg.dev/sw02-hpch-0/sw02-0-tsb-repo/proxyv2:1.19.5-f764c5d759-distroless,docker.io/istio/examples-bookinfo-reviews-v3:1.16.4
```
