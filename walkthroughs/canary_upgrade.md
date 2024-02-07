# Revision Upgrades

## Summary

This walkthrough completes a `Control Plane` upgrade and takes a phased approach to upgrade the `Data Plane`. This is achieved by creating a new revision of the Isolation Boundary and updating the namespace to use the new revision.

## Pre-requisites

- Ensure that the Management Plane is upgraded to the Target Version.
- Ensure that `tctl install image-sync` is completed for the Target Version.
- Run `make argocd` and ensure that the bookinfo application is deployed
- The `yq` tool is installed (used to update yaml files)

## Upgrade Control Plane

The following steps are performed to upgrade the Control Plane

### Set Environment Variables

```sh
CLUSTER_NAME="gke-sw02-us-west1-0"
CURRENT_VERSION="1.8.0-internal-rc3"
UPGRADE_VERSION="1.8.0"

```

### Setup Revision and Upgrade ControlPlane

```sh

# Delete the bookinfo argocd application so the namespace doesn't reconcile
k delete applications.argoproj.io bookinfo -n argocd   

# Obtain Helm values used for installation
helm get values controlplane -n istio-system -o yaml > $CLUSTER_NAME-cp.yaml

# Update the version configured in Helm values
yq eval-all '.image.tag = "'${UPGRADE_VERSION}'"' $CLUSTER_NAME-cp.yaml -i

# Extract Default IsolationBoundary Properties from the ControlPlane Manifest
k get controlplane controlplane -o yaml -n istio-system | yq .spec.components.xcp.isolationBoundaries > IB-$CLUSTER_NAME-$UPGRADE_VERSION.yaml

# Update the IsolationBoundary File to reflect the new revision for the default IsolationBoundary
yq eval-all '.[0].revisions += {"name": "default'$(echo "$UPGRADE_VERSION" | tr '.' '-')'", "istio": {"tsbVersion": "'${UPGRADE_VERSION}'"}}' IB-$CLUSTER_NAME-$UPGRADE_VERSION.yaml -i

# Merge Revisions into ControlPlane Helm values
IB_OUTPUT=$(yq . IB-$CLUSTER_NAME-$UPGRADE_VERSION.yaml) yq eval-all '.spec.components.xcp.isolationBoundaries = env(IB_OUTPUT)' $CLUSTER_NAME-cp.yaml -i

# Upgrade Control Plane
helm upgrade controlplane -n istio-system -f $CLUSTER_NAME-cp.yaml tetrate-tsb-helm/controlplane --version $UPGRADE_VERSION
```

### Verify Control Plane Upgrade

With a new revision, we expect to see my `default` istiod pod and another `istiod` with the revision name

```sh
kubectl get pod -n istio-system -l app=istiod
NAME                                   READY   STATUS    RESTARTS   AGE
istiod-7b5ddb998f-482cx                1/1     Running   0          14h
istiod-default1-8-0-7887f9c59d-m77qb   1/1     Running   0          1h
istiod-dev-stable-58544c4587-pt6tk     1/1     Running   0          14h
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

**_NOTE: alias kip="kubectl get pods -o=custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[*].image'"_**

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
kubectl label ns bookinfo istio.io/rev=default1-8-0
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