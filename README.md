# Tetrate Service Bridge Sandbox

## About
---

## Deploy Tetrate Service Bridge Demo on Azure Kubernetes Service (AKS), Google Kubernetes Engine (GKE) and/or Elastic Kubernetes Service (EKS) using Terraform

The intention is to create a go-to demo from deploying underlying infra environment to deploying MP and CP and additional addons around usecases

## Overview

The `Makefile` in this directory provides automated provisioning of TSB demo and necessary dependencies

```mermaid
  graph TD;
      A[make tsb] --> B[make k8s]
      B[make k8s] --> C[make aws_k8s]
      B[make k8s] --> CC[make azure_k8s]
      B[make k8s] --> CCC[make gcp_k8s]
      C[make aws_k8s] --> D[make tsb_mp]
      CC[make azure_k8s] --> D[make tsb_mp]
      CCC[make gcp_k8s] --> D[make tsb_mp]
      D[make tsb_mp] --> DD[make tsb_cp]
      D[make tsb_mp] --> G[make argocd]
      D[make tsb_mp] --> F[make keycloak]
      style F fill:lightgrey
```

# Getting Started

## Requirements

- terraform >= 1.0.0
- AWS role configured and assumed(Route53 is used for TSB MP FQDN)
- (optional) Azure role configured and assumed 
- (optional) GCP role configured and assumed  `gcloud auth application-default login`

## Setup
1. Clone the repo
```bash
git clone https://github.com/smarunich/tetrate-service-bridge-sandbox.git
```
2. Copy `terraform.tfvars.json.sample` to the root directory as `terraform.tfvars.json`

```json
{
    "name_prefix": <YOUR UNIQUE PREFIX NAME TO BE CREATED>,
    "tsb_fqdn": <YOUR UNIQUE PREFIX NAME TO BE CREATED>".cx.tetrate.info",
    "tsb_version": "1.5.0",
    "tsb_image_sync_username": <TSB_REPO_USERNAME>,
    "tsb_image_sync_apikey": <TSB_REPO_APIKEY>,
    "tsb_password": "Tetrate123",
    "tsb_mp": {
        "cloud": "gcp",
        "cluster_id": 0
    },
    "tsb_org": "tetrate",
    "aws_k8s_regions": [
    ],
    "azure_k8s_regions": [
    ],
    "gcp_k8s_regions": [
        "us-west1",
        "us-east1"
    ]
}
```

## Usage

1. a) Stand up full demo

```bash
# Build full demo
make tsb
```

1. b) Decouple demo/Deploy in stages

```bash
# setup underlying clusters, registries, jumpboxes
make k8s

# deploy tsb management plane
make tsb_mp

# onboard deployed clusters (dataplane/controlplane)
make tsb_cp
```

The completion of the above steps will result in:
- all the generated outputs will be provided under `./outputs` folder
- output kubeconfig files for all the created aks clusters in format of: $cluster_name-kubeconfig
- output IP address and private key for the jumpbox (ssh username: tsbadmin), using shell scripts login to the jumpbox, for example to reach gcp jumpbox just run the script `ssh-to-gcp-jumpbox.sh`

## Use Cases
### ArgoCD (```make argocd```)

```bash
# deploy argocd on the management cluster
make argocd
```

- deploys bookinfo app under gitops-bookinfo namespace and exposes it over the ingress gateway as gitops-bookinfo.tetrate.io
- argocd is exposed using `LoadBalancer` type `k get svc -n argocd argo-cd-argocd-server`, the username is admin and password is the specified TSB admin password

## CleanUp

When you are done with the environment, you can destroy it by running:

```bash
make destroy
```

### Usage notes

- Terraform destroys only the resources it created.
- Terraform stores the `state` across workspaces in different folders locally
- Terraform destroy wont delete aws objects created by K8s loadbalancer services (ELB+SGs)
