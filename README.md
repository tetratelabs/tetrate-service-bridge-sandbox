# Tetrate Service Bridge Sandbox

### Deploy Tetrate Service Bridge Demo on Azure Kubernetes Service (AKS), Google Kubernetes Engine (GKE) and/or Elastic Kubernetes Service (EKS) using Terraform

---

## About

The intention is to create a go-to demo from deploying underlying infra environment to deploying MP and CP and additional addons around usecases

## Overview

The `Makefile` in this directory provides ability to fastforward to anypoint of the automated provisioning of the TSB demo

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

## Prerequisites

- terraform >= 1.0.0
- AWS role configured and assumed(Route53 is used for TSB MP FQDN)
- (optional) Azure role configured and assumed
- (optional) GCP role configured and assumed `gcloud auth application-default login`

## Setup

1. Clone the repo

```bash
git clone https://github.com/smarunich/tetrate-service-bridge-sandbox.git
```

2. Copy `terraform.tfvars.json.sample` to the root directory as `terraform.tfvars.json`

Please refer to [tfvars collection](/tfvars_collection) for more examples, i.e. tested options.

```json
{
  "name_prefix": "<YOUR UNIQUE PREFIX NAME TO BE CREATED>",
  "tsb_fqdn": "<YOUR UNIQUE PREFIX NAME TO BE CREATED>.cx.tetrate.info",
  "tsb_version": "1.5.0",
  "tsb_image_sync_username": "<TSB_REPO_USERNAME>",
  "tsb_image_sync_apikey": "<TSB_REPO_APIKEY>",
  "tsb_password": "Tetrate123",
  "tsb_mp": {
    "cloud": "azure",
    "cluster_id": 0
  },
  "tsb_org": "tetrate",
  "aws_k8s_regions": [],
  "azure_k8s_regions": ["eastus"],
  "gcp_k8s_regions": ["us-west1", "us-east1"]
}
```

###More [tfvars](/tfvars_collection):

| Links                                                                                                                   | Description                          |
| :---------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| [mp-aks-cp-1aks-2gke-terraform.tfvars.json.sample](/tfvars_collection/mp-aks-cp-1aks-2gke-terraform.tfvars.json.sample) | MP on AKS, CP on 1xAKS, 2xGKE        |
| [mp-eks-cp-1aks-1eks-2gke.tfvars.json.sample](/tfvars_collection/mp-eks-cp-1aks-1eks-2gke.tfvars.json.sample)           | MP on EKS, CP on 1xAKS, 1xEKS, 2xGKE |
| [mp-gke-cp-1aks-1eks-2gke.tfvars.json.sample](/tfvars_collection/mp-gke-cp-1aks-1eks-2gke.tfvars.json.sample)           | MP on GKE, CP on 1xAKS, 1xEKS, 2xGKE |
| [mp-gke-cp-1aks-2gke.tfvars.json.sample](/tfvars_collection/mp-gke-cp-1aks-2gke.tfvars.json.sample)                     | MP on GKE, CP on 1xAKS, 2xGKE        |
| [mp-gke-cp-3gke.tfvars.json.sample](/tfvars_collection/mp-gke-cp-3gke.tfvars.json.sample)                               | MP on GKE, CP on 3xGKE               |

## Usage

All `Make` commands should be executed from root of repo as this is where `Make` file is.

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

## Deployment Scenarios

[Infra Staging](./infra/README.md)<br>
[TSB MP Fastforward](./tsb/README.md#tsb_mp)<br>
[TSB CP Fastforward](./tsb/README.md#tsb_cp)<br>

## Usecases

[Argocd GITOPs](./addons/README.md#argocd)

## CleanUp

When you are done with the environment, you can destroy it by running:

```bash
make destroy
```

### Usage notes

- Terraform destroys only the resources it created (`make destroy`)
- Terraform stores the `state` across workspaces in different folders locally
- Cleanup of aws objects created by K8s loadbalancer services (ELB+SGs) is currently manual effort
