# Tetrate Service Bridge Sandbox

### Deploy Tetrate Service Bridge Demo on Azure Kubernetes Service (AKS), Google Kubernetes Engine (GKE) and/or Elastic Kubernetes Service (EKS) using Terraform

---

## About

The intention is to create a go-to demo from deploying underlying infra environment to deploying MP and CP and additional addons around usecases

## Overview

The `Makefile` in this directory provides ability to fastforward to anypoint of the automated provisioning of the TSB demo

```mermaid
  graph TD;
      tsb[make tsb] --> k8s[make k8s]
      k8s --> aws[make aws_k8s]
      k8s --> azure[make azure_k8s]
      k8s --> gcp[make gcp_k8s]
      aws --> mp[make tsb_mp]
      azure --> mp
      gcp --> mp
      mp --> cp[make tsb_cp]
      subgraph Add-Ons
        monitoring[make monitoring]
        argocd[make argocd]
        external-dns[make external-dns]
      end
      cp --> argocd
      cp --> external-dns
      mp --> monitoring
```

# Getting Started

## Prerequisites

- terraform >= 1.3.6
- AWS role configured and assumed (Route53 is used for TSB MP FQDN)
- (optional) Azure role configured and assumed
- (optional) GCP role configured and assumed `gcloud auth application-default login`

## Setup

1. Clone the repo

```bash
git clone https://github.com/tetrateio/tetrate-service-bridge-sandbox.git
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

### More [tfvars](/tfvars_collection):

| Links                                                                                                                   | Description                                                 |
| :---------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| [mp-aks-cp-1aks-2gke-terraform.tfvars.json.sample](/tfvars_collection/mp-aks-cp-1aks-2gke-terraform.tfvars.json.sample) | MP on AKS, CP on 1xAKS, 2xGKE                               |
| [mp-eks-cp-1aks-1eks-2gke.tfvars.json.sample](/tfvars_collection/mp-eks-cp-1aks-1eks-2gke.tfvars.json.sample)           | MP on EKS, CP on 1xAKS, 1xEKS, 2xGKE                        |
| [mp-gke-cp-1aks-1eks-2gke.tfvars.json.sample](/tfvars_collection/mp-gke-cp-1aks-1eks-2gke.tfvars.json.sample)           | MP on GKE, CP on 1xAKS, 1xEKS, 2xGKE                        |
| [mp-gke-cp-1aks-2gke.tfvars.json.sample](/tfvars_collection/mp-gke-cp-1aks-2gke.tfvars.json.sample)                     | MP on GKE, CP on 1xAKS, 2xGKE                               |
| [mp-gke-cp-3gke.tfvars.json.sample](/tfvars_collection/mp-gke-cp-3gke.tfvars.json.sample)                               | MP on GKE, CP on 3xGKE                                      |
| [mp-gke-cp-2aks-2eks-2gke.tfvars.json.sample](/tfvars_collection/mp-gke-cp-2aks-2eks-2gke.tfvars.json.sample)            | MP on GKE, CP on 2xAKS, 2xEKS, 2xGKE within the same region |

## Usage

All `Make` commands should be executed from root of repo as this is where the `Makefile` is.

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

## Use Cases

[ArgoCD GitOps](./addons/README.md#argocd)

## Destroy

When you are done with the environment, you can destroy it by running:

```bash
make destroy
```

For a quicker destroy for development purposes, you can:

- manually delete the clusters via CLI or web consoles 
- run `make destroy_local` to delete the terraform data

## Dev Environment (Tetrate Internal)

[If you want to provision the latest master build](./DEVELOPMENT_BUILD.md)

## Usage notes

- Terraform destroys only the resources it created (`make destroy`)
- Terraform stores the `state` across workspaces in different folders locally
- Cleanup of aws objects created by K8s loadbalancer services (ELB+SGs) is currently manual effort
- When using GCP, it is possible to use the DNS of the current project instead of the shared one. This may
  be convenient if you don't have permissions to create DNS records in the shared DNS project. To have the
  DNS records created in your project, just use any `fqdn` you want that ends in `.private`. Note that
  `.private` domains won't work in multicluster scenarios, since XCP Edges need a public name to connect to
  Central.
  Alternatively, if you own a domain that you can point to your GCP project, you can use any `fqdn` as long
  as it does _not_ have the shared DNS suffix (gcp.cx.tetrate.info). In this case a public DNS zone will be
  created in the project for the configured DNS domain.

### Repository structure

| Directory | Description |
| --------- | ----------- |
| [addons](addons) | Terraform modules to deploy optional add-ons such as ArgoCD or the TSB monitoring stack. |
| [gitops](gitops) | Example application configurations to be used with the ArgoCD addon. |
| [infra](infra) | Infrastructure deployment modules. Provisioning of networking, jumpboxes and k8s clusters. |
| [modules](modules) | Generic and reusable terraform modules. These should not contain any specific configuration. |
| [outputs](outputs) | Terraform output values for the provisioned modules. |
| [tsb](tsb) | TSB Terraform modules to deploy the TSB MP and TSB CPs. |
