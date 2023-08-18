# Addons

## Prerequisites

* terraform >= 1.0.0
* AWS role configured and assumed(Route53 is used for TSB MP FQDN)
* (optional) Azure role configured and assumed
* (optional) GCP role configured and assumed  `gcloud auth application-default login`

## ArgoCD

Deploys Argo CD for gitops demo

```bash
# Deploys Argocd on all Clusters
make argocd
```

`argocd` is exposed using LoadBalancer type `kubectl get svc -n argocd argo-cd-argocd-server`, the username is `admin`
and the password can be found in the `outputs/terraform_outputs/terraform-argocd-<cloud>-<cluster_id>.json` file
(defaults to the `tsb_password` if set).

For details about the deployed applications, take a look at the manifests in the `applications` folder.

## FluxCD

Deploys Flux CD for gitops demo

```bash
# Deploys Argocd on all Clusters
make fluxcd
```

For details about the deployed applications, take a look at the manifests in the `applications` folder.

## TSB monitoring stack

Deploys the TSB monitoring stack to have metrics and dashboards showing the operational status
of the different TSB components.

```bash
# Deploys the TSB monitoring stack in the management plane cluster
make tsb-monitoring
```

`grafana` is exposed using ClusterIP type. It can be accessed by port-forwarding port 3000 to the `grafana` pod
in the `tsb-monitoring` namespace. The username is `admin` and the password can be found in the
`outputs/terraform_outputs/terraform-tsb-monitoring.json` file (defaults to the `tsb_password` if set).

## external-dns 

Deploys external-dns per k8s cluster, where the DNS domain equals to `$var.cluster_name`.`$var.external_dns_$cloud_dns_zone`.
For example, where the cluster name is `gke-r161rc1p1-us-east1-0` and `var.external_dns_gcp_dns_zone` is set to `gcp.sandbox.tetrate.io` - the DNS domain will equal to `gke-r161rc1p1-us-east1-0.gcp.sandbox.tetrate.io`, and the sample DNS record will equal to `test3.gke-r161rc1p1-us-east1-0.gcp.sandbox.tetrate.io`.

### General Defaults 

```hcl
variable "external_dns_annotation_filter" {
  default = ""
}

variable "external_dns_label_filter" {
  default = ""
}

variable "external_dns_sources" {
  default = "service"
}

variable "external_dns_interval" {
  default = "5s"
}
```

#### GCP Defaults

```hcl
variable "external_dns_gcp_dns_zone" {
  default = "gcp.sandbox.tetrate.io"
}
```

#### Azure Defaults

```hcl
variable "external_dns_azure_dns_zone" {
  default = "azure.sandbox.tetrate.io"
}
```

### Deploy

Based on the cloud `external_dns_$cloud_dns_zone` variable have to be set or overwritten in `terraform.tfvars` file.
> NOTE:  AWS does not have a default external-dns zone set.

terraform.tfvars.json:
```json
...
"external_dns_aws_dns_zone": "aws.sandbox.tetrate.io"
...
```

```bash
make external_dns
```

or per cloud, for example GCP:

```bash
make external_dns_gcp
```

### Destroy

```bash
make destroy_external_dns
```

or per cloud, for example GCP:

```bash
make destroy_external_dns_gcp
```

### Module Overview

#### module.argocd (`make argocd`)
* Deploys ArgoCD
* bookinfo demo app using ArgoCD with related TSB components.
* grpc demo app using ArgoCD with related TSB components.
* eshop demo app using ArgoCD with related TSB components.

#### module.monitoring (`make monitoring`)
* Deploys the TSB monitoring stack.
* prometheus configured to scrape all the TSB and XCP components.
* grafana with TSB operational dashboards preloaded and configured.
