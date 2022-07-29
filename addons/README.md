# Addons

## Prerequisites

- terraform >= 1.0.0
- AWS role configured and assumed(Route53 is used for TSB MP FQDN)
- (optional) Azure role configured and assumed 
- (optional) GCP role configured and assumed  `gcloud auth application-default login`

## Argocd
Deploy Argo CD for gitops demo

```bash
# Deploys Argocd on TSB Management Plane Cluster
make argocd
```
- deploys bookinfo app under namespace `gitops-bookinfo`  and exposes it over the ingress gateway as `gitops-bookinfo.tetrate.io`
- argocd is exposed using LoadBalancer type k get svc -n argocd argo-cd-argocd-server, the username is `admin` and password is variable `tsb_password` from `tfvar`
### Module Overview
---

-- argocd (`make argocd`)
- module.argocd - deploys argoCD
  bookinfo demo app using ArgoCD with related TSB components
  grpc demo app using ArgoCD with related TSB components

-- keycloak (In progress)
- module.keycloak-helm - deploys keycloak
- module.keycloak-provider - configs keycloak for JWT-based external authorization demo
- module.app_bookinfo - deploys bookinfo
