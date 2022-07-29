# Tetrate Service Bridge Standup

- mp = Management Plane
- cp = Control and Dataplane

## Prerequisites
- terraform >= 1.0.0
- AWS role configured and assumed(Route53 is used for TSB MP FQDN)
- (optional) Azure role configured and assumed 
- (optional) GCP role configured and assumed  `gcloud auth application-default login`

## tsb_mp

Prepare Infra components with TSB Management Plane <br>
`Note`: Management Plane Cluster is selected based off `tsb_mp` variable
```json
    "tsb_mp": {
        "cloud": "aws",
        "cluster_id": 0
    },
```
Execute:
```bash
# Infra deployed + TSB Management Plane
make tsb_mp
```

## tsb_cp

Prepare Infra components with TSB Managementplane and TSB Control plane for all clusters deployed

```bash
# Infra deployed + TSB Management Plane
make tsb_cp
```

### Module Overview
---
-- mp (`make tsb_mp`)
- module.cert-manager - deploys cert-manager on k8s cluster
- module.tsb_mp - responsible for TSB MP setup using Helm chart
- module.es - deploys ElasticSearch on MP k8s cluster
- module.aws_route53_register_fqdn - responsible for TSB Public FQDN setup

-- cp (`make tsb_cp`)
- module.cert-manager - deploys cert-manager on CP k8s cluster
- module.tsb_cp - responsible for TSB CP setup using Helm chart
