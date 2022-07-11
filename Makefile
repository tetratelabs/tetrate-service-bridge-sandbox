# Copyright (c) Tetrate, Inc 2021 All Rights Reserved.
# 
# Default variables
cluster_id = 1
cloud = azure
terraform_apply_args = -auto-approve
terraform_destroy_args = -auto-approve
#terraform_apply_args = 
# Functions

.PHONY: all
all: k8s tsb_mp tsb_cp argocd

.PHONY : help
help : Makefile
	@sed -n 's/^##//p' $<

## init					 	 terraform init
.PHONY: init
init:
	terraform init

## azure_jumpbox					 deploys jumpbox, pushes tsb repo to acr
.PHONY: azure_jumpbox
azure_jumpbox:
	terraform apply ${terraform_apply_args} -target=module.azure_base -target=module.azure_jumpbox

## aws_jumpbox					 deploys jumpbox, pushes tsb repo to acr
.PHONY: aws_jumpbox
aws_jumpbox:
	terraform apply ${terraform_apply_args} -target=module.aws_base -target=module.aws_jumpbox


## gcp_jumpbox					 deploys jumpbox, pushes tsb repo to gcr
.PHONY: gcp_jumpbox
gcp_jumpbox:
	terraform apply ${terraform_apply_args} -target=module.gcp_base -target=module.gcp_jumpbox

## k8s						 deploys k8s cluster for MP and N-number of CPs(*) 
.PHONY: k8s
k8s:
	terraform apply ${terraform_apply_args} -target=module.azure_base
	terraform apply ${terraform_apply_args} -target=module.azure_jumpbox 
	terraform apply ${terraform_apply_args} -target=module.azure_k8s
	terraform apply ${terraform_apply_args} -target=module.aws_base 
	terraform apply ${terraform_apply_args} -target=module.aws_jumpbox 
	terraform apply ${terraform_apply_args} -target=module.aws_k8s
	terraform apply ${terraform_apply_args} -target=module.gcp_base 
	terraform apply ${terraform_apply_args} -target=module.gcp_jumpbox 
	terraform apply ${terraform_apply_args} -target=module.gcp_k8s

## azure_k8s					 deploys azure k8s cluster for MP and N-number of CPs(*) leveraging AKS
.PHONY: azure_k8s
azure_k8s:
	terraform apply ${terraform_apply_args} -target=module.azure_base
	terraform apply ${terraform_apply_args} -target=module.azure_jumpbox 
	terraform apply ${terraform_apply_args} -target=module.azure_k8s

## aws_k8s					 deploys EKS K8s cluster (CPs only)
.PHONY: aws_k8s
aws_k8s:
	terraform apply ${terraform_apply_args} -target=module.aws_base 
	terraform apply ${terraform_apply_args} -target=module.aws_jumpbox 
	terraform apply ${terraform_apply_args} -target=module.aws_k8s

## gcp_k8s					 deploys GKE K8s cluster (CPs only)
.PHONY: gcp_k8s
gcp_k8s:
	terraform apply ${terraform_apply_args} -target=module.gcp_base 
	terraform apply ${terraform_apply_args} -target=module.gcp_jumpbox 
	terraform apply ${terraform_apply_args} -target=module.gcp_k8s

.PHONY: tsb_deps
tsb_deps: 
	@echo "Deploying TSB MP preqs to azure cluster with cluster_id=0"
  ## working around the issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/2602
	terraform apply ${terraform_apply_args} -target=module.azure_k8s -target=module.aws_base -target=module.aws_jumpbox  
	terraform apply ${terraform_apply_args} -target=module.cert-manager -target=module.es -var=cluster_id=0 -var=cloud=azure

## tsb_mp						 deploys MP
.PHONY: tsb_mp
tsb_mp: tsb_deps
	@echo "Deploying TSB MP to azure cluster with cluster_id=0"
  ## working around the issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/2602
	terraform apply ${terraform_apply_args} -target=module.azure_k8s -target=module.aws_base -target=module.aws_jumpbox 
	terraform apply ${terraform_apply_args} -target=module.tsb_mp.kubectl_manifest.manifests_certs
	terraform apply ${terraform_apply_args} -target=module.tsb_mp
	terraform apply ${terraform_apply_args} -target=module.aws_route53_register_fqdn -var=cluster_id=0 -var=cloud=azure

## tsb_fqdn					 creates TSB MP FQDN
.PHONY: tsb_fqdn
tsb_fqdn:
	terraform apply ${terraform_apply_args} -target=module.aws_route53_register_fqdn -var=cluster_id=0 -var=cloud=azure

## tsb_cp	cluster_id=1 cloud=azure		 onboards CP on AKS cluster with ID=1 
.PHONY: tsb_cp
tsb_cp:
	@echo "Onboarding ${cloud} cluster with cluster_id=${cluster_id} into TSB"
	#terraform state list | grep "^module.cert-manager" | grep -v data | grep -v manifest | grep -v helm | grep -v wait| tr -d ':' | xargs -I '{}' terraform taint {}
	terraform taint -allow-missing "module.cert-manager.time_sleep.wait_90_seconds"
	terraform taint -allow-missing "module.tsb_cp.null_resource.jumpbox_tctl"
  ## working around the issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/2602
	terraform apply ${terraform_apply_args} -target=module.azure_k8s -target=module.aws_base -target=module.aws_jumpbox  
	terraform apply ${terraform_apply_args} -target=module.cert-manager -var=cluster_id=${cluster_id} -var=cloud=${cloud}
	terraform apply ${terraform_apply_args} -target=module.tsb_cp -var=cluster_id=${cluster_id} -var=cloud=${cloud}

## argocd cluster_id=1 cloud=azure		 onboards ArgoCD on AKS cluster with ID=1 
.PHONY: argocd
argocd:
	@echo "Deploying ArgoCD to ${cloud} cluster with cluster_id=${cluster_id}"
  ## working around the issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/2602
	terraform apply ${terraform_apply_args} -target=module.azure_k8s -target=module.aws_base -target=module.aws_jumpbox 
	terraform apply ${terraform_apply_args} -target=module.argocd -var=cluster_id=${cluster_id} -var=cloud=${cloud}

.PHONY: keycloak
keycloak:
  ## working around the issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/2602
	terraform apply ${terraform_apply_args} -target=module.azure_k8s -target=module.aws_base -target=module.aws_jumpbox 
	terraform apply ${terraform_apply_args} -target=module.keycloak-helm -var=cluster_id=0

.PHONY: app_bookinfo
app_bookinfo:
	@echo "Deploying bookinfo application to ${cloud} cluster with cluster_id=${cluster_id}"
	terraform state list | grep "^module.app_bookinfo" | grep -v data | tr -d ':' | xargs -I '{}' terraform taint {}
  ## working around the issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/2602
	terraform apply ${terraform_apply_args} -target=module.azure_k8s -target=module.aws_base -target=module.aws_jumpbox 
	terraform apply ${terraform_apply_args} -target=module.app_bookinfo -var=cluster_id=${cluster_id} -var=cloud=${cloud}

.PHONY: azure_oidc
azure_oidc:
	terraform apply ${terraform_apply_args} -target=module.azure_oidc

## destroy					 destroy the environment
.PHONY: destroy
destroy:
	terraform destroy ${terraform_destroy_args} -refresh=false -target=module.aws_route53_register_fqdn
	terraform state list | grep "^module.tsb" | xargs -I '{}'  terraform state rm {}
	terraform state list | grep "^module.cert" | xargs -I '{}'  terraform state rm {}
	terraform state list | grep "^module.argo" | xargs -I '{}'  terraform state rm {}
	terraform state list | grep "^module.es" | xargs -I '{}'  terraform state rm {}
	terraform state list | grep "^module.keycloak" | xargs -I '{}'  terraform state rm {}
	terraform state list | grep "^module.app" | xargs -I '{}'  terraform state rm {}
	terraform destroy ${terraform_destroy_args} -refresh=false -target=module.aws_k8s -target=module.aws_jumpbox  -target=module.aws_base
	terraform destroy ${terraform_destroy_args} -refresh=false -target=module.azure_k8s  -target=module.azure_jumpbox -target=module.azure_base
	terraform destroy ${terraform_destroy_args} -refresh=false 
	terraform destroy ${terraform_destroy_args}
