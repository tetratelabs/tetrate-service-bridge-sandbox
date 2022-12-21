# Addons

## Prerequisites

- terraform >= 1.0.0
- AWS role configured and assumed(Route53 is used for TSB MP FQDN)
- (optional) Azure role configured and assumed 
- (optional) GCP role configured and assumed  `gcloud auth application-default login`

## Argocd
Deploy Argo CD for gitops demo

```bash
# Deploys Argocd on all Clusters
make argocd
```
- deploys bookinfo app under namespace `gitops-bookinfo`  and exposes it over the ingress gateway as `gitops-bookinfo.tetrate.io`
- argocd is exposed using LoadBalancer type k get svc -n argocd argo-cd-argocd-server, the username is `admin` and password is variable `tsb_password` from `tfvar`
### Module Overview

#### argocd (`make argocd`)
* module.argocd - deploys argoCD
  bookinfo demo app using ArgoCD with related TSB components
  grpc demo app using ArgoCD with related TSB components
  eshop demo app using ArgoCD with related TSB components

#### monitoring (`make monitoring`)
* module.monitoring - deploys the TSB monitoring stack
  prometheus configured to scrape all the TSB and XCP components
  grafana with TSB operational dashboards preloaded and configured. It can be
  accessed by port-forwarding port 3000 to the `grafana` pod in the `tsb-monitoring`
  namespace.

#### keycloak (In progress)
* module.keycloak-helm - deploys keycloak
* module.keycloak-provider - configs keycloak for JWT-based external authorization demo
* module.app_bookinfo - deploys bookinfo
