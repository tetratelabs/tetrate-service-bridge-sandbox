# Canary Releases

## Summary

This walkthrough how to do a canary release for bookinfo reviews service.

- [Canary Releases KB](https://docs.tetrate.io/service-bridge/howto/traffic/canary_releases)

## Pre-requisites

- Run `make argocd` and ensure that the bookinfo application is deployed

## Application Description

The application used will be [bookinfo application](https://istio.io/latest/docs/examples/bookinfo/noistio.svg) and the focus will be on canary release of the `reviews` service for `v1` and `v2`.

### Setup Base ServiceRoute

Will set up a base `ServiceRoute` to prefer `v1` subset

```sh
cat <<EOF | kubectl apply -f -
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: bookinfo-sr-reviews
  namespace: bookinfo
  annotations:
    group: bookinfo-tg
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: dev
    tsb.tetrate.io/workspace: bookinfo-ws
    tsb.tetrate.io/trafficGroup: bookinfo-tg
spec:
  service: bookinfo/reviews.bookinfo.svc.cluster.local
  portLevelSettings:
    - port: 9080
      trafficType: HTTP
  subsets:
  - name: v1
    labels:
      version: v1
    weight: 100
  - name: v2
    labels:
      version: v2
    weight: 0
  - name: v3
    labels:
      version: v3
    weight: 0
EOF
```

Using `curl` run the following command a couple times to see the different versions of the `reviews` service:
```sh
curl internal-bookinfo.tetrate.io/productpage --resolve internal-bookinfo.tetrate.io:80:$GATEWAY_IP  | grep reviews
```

### Setup ServiceRoute for Canary

Update `ServiceRoute` to split traffic between `v1` at 70% and `v2` at 30%

```sh
cat <<EOF | kubectl apply -f -
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: bookinfo-sr-reviews
  namespace: bookinfo
  annotations:
    group: bookinfo-tg
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: dev
    tsb.tetrate.io/workspace: bookinfo-ws
    tsb.tetrate.io/trafficGroup: bookinfo-tg
spec:
  service: bookinfo/reviews.bookinfo.svc.cluster.local
  portLevelSettings:
    - port: 9080
      trafficType: HTTP
  subsets:
  - name: v1
    labels:
      version: v1
    weight: 70
  - name: v2
    labels:
      version: v2
    weight: 30
  - name: v3
    labels:
      version: v3
    weight: 0
EOF
```

Using `curl` run the following command a couple times to see the different versions of the `reviews` service:
```sh
curl internal-bookinfo.tetrate.io/productpage --resolve internal-bookinfo.tetrate.io:80:$GATEWAY_IP  | grep reviews
```

## Cleanup

```sh
kubectl delete serviceroute bookinfo-sr-reviews -n bookinfo 
```