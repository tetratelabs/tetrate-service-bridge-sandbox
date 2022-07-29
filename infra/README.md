# Infra Standup

## Prerequisites

This is clean base install of infra for all other components to get deployed ontop.  
- terraform >= 1.0.0
- AWS role configured and assumed(Route53 is used for TSB MP FQDN)
- (optional) Azure role configured and assumed 
- (optional) GCP role configured and assumed  `gcloud auth application-default login`

## Usage
To deploy infrastructure only

```bash
# setup underlying clusters, registries, jumpboxes
make k8s
```

### Module Overview (`make k8s`)
---
-- azure (`make azure_k8s`)
- module.azure_base - deploys resource group, vnet and acr
- module.azure_jumpbox - deploys jumpbox, pushes tsb repo to acr
- module.azure_k8s - deploys k8s cluster leveraging AKS

-- gcp (`make gcp_k8s`)
- google_project - deploys new project
- module.gcp_base - deploys network, router, firewall, enable apis
- module.gcp_jumpbox - deploys jumpbox, pushes tsb repo to cr
- module.gcp_k8s - deploys k8s cluster leveraging GKE

-- aws (`make aws_k8s`)
- module.aws_base - deploys vpc, subnet, gateway, routes, ecr
- module.aws_jumpbox - deploys jumpbox, pushes tsb repo to ecr
- module.aws_k8s - deploys k8s cluster leveraging EKS
