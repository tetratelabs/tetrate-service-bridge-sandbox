# Request Routing - Header Based Example

## Summary

How to setup subset based traffic routing by matching traffic on uri endpoint, header and port and routing it to destination service's.

- [Request Routing KB](https://docs.tetrate.io/service-bridge/howto/gateway/subset-based-routing-using-igw-and-service-route)

## Pre-requisites

- Run `make argocd` and ensure that the bookinfo application is deployed

## Application Description

The application used will be [bookinfo application](https://istio.io/latest/docs/examples/bookinfo/noistio.svg) and the focus will be on adjusting the subsets for the 3 versions of the `reviews` service.

### Current Application Configuration

```sh
export GATEWAY_NAME=app-gw
export GATEWAY_NS=bookinfo
# Note: If using AWS will need to adjust jsonpath as: jsonpath='{.status.loadBalancer.ingress[0].hostname}' and resolve hostname to IP
export GATEWAY_IP=$(kubectl -n "$GATEWAY_NS" get service "$GATEWAY_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

Using `curl` run the following command a couple times to see the different versions of the `reviews` service:
```sh
curl internal-bookinfo.tetrate.io/productpage --resolve internal-bookinfo.tetrate.io:80:$GATEWAY_IP  | grep reviews
```

### Request Routing

In this example we define a `ServiceRoute` where there will be 3 subsets:
- v1 (no stars) Old Version so no longer used
- v2 (black stars) Current Version
- v3 (red stars) New Version being tested, only reachable via `end-user: jason` header

```yaml
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
    weight: 0
  - name: v2
    labels:
      version: v2
    weight: 0
  - name: v3
    labels:
      version: v3
    weight: 0
  httpRoutes:
    - name: http-route-match-header
      match:
        - name: match-header-only
          headers:
            end-user: 
              exact: jason
          port: 9080
      destination:
      - subset: v3
        weight: 100
        port: 9080
    - name: http-route-default
      match:
        - name: match-default
          port: 9080
      destination:
        - subset: v2
          weight: 100
          port: 9080
EOF
```

### Testing

### First test non-authenticated user requests

Using `curl` response should show only `reviews-v2``:
```sh
# Send request to the productpage and verify that the reviews are now from `reviews-v2` service
curl internal-bookinfo.tetrate.io/productpage --resolve internal-bookinfo.tetrate.io:80:$GATEWAY_IP  | grep reviews
```

### Authenticate as user: jason

```sh
# Perform login and capture the session cookie into an environment variable
SESSION_COOKIE=$(curl -c - -d 'username=jason&passwd=' -X POST http://internal-bookinfo.tetrate.io/login --resolve internal-bookinfo.tetrate.io:80:$GATEWAY_IP | awk '/^#HttpOnly_internal-bookinfo.tetrate.io/{print $NF}')

# Display/Verify the obtained session cookie
echo "Session Cookie: $SESSION_COOKIE"

# Send request to the productpage and verify that the reviews are now from `reviews-v3` service
curl -b "session=$SESSION_COOKIE" --resolve internal-bookinfo.tetrate.io:80:$GATEWAY_IP http://internal-bookinfo.tetrate.io/productpage | grep reviews
```

## Cleanup

```sh
kubectl delete serviceroute bookinfo-sr-reviews -n bookinfo 
```