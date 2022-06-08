# Copyright (c) Tetrate, Inc 2021 All Rights Reserved.
# 
# Default variables
cluster_id = 1
cloud = azure
# Functions

.PHONY : help
help : Makefile
	@sed -n 's/^##//p' $<

## azure_jumpbox					 deploys jumpbox, pushes tsb repo to acr
.PHONY: azure_jumpbox
azure_jumpbox:
	terraform init
	terraform apply -auto-approve -target=module.azure_base -target=module.azure_jumpbox

## aws_jumpbox					 deploys jumpbox, pushes tsb repo to acr
.PHONY: aws_jumpbox
aws_jumpbox:
	terraform init
	terraform apply -auto-approve -target=module.aws_base -target=module.aws_jumpbox

## azure_k8s					 deploys azure k8s cluster for MP and N-number of CPs(*) leveraging AKS
.PHONY: azure_k8s
azure_k8s:
	terraform init
	terraform apply -auto-approve -target=module.azure_base -target=module.azure_jumpbox -target=module.azure_k8s

## aws_k8s					 deploys EKS K8s cluster (CPs only)
.PHONY: aws_k8s
aws_k8s:
	terraform init
	terraform apply -auto-approve -target=module.aws_base -target=module.aws_jumpbox -target=module.aws_k8s

.PHONY: tsb_deps
tsb_deps: 
  ## working around the issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/2602
	terraform apply -auto-approve -target=module.azure_k8s -target=module.aws_base -target=module.aws_jumpbox  
	terraform apply -auto-approve -target=module.cert-manager -target=module.es -var=cluster_id=0 -var=cloud=azure

## tsb_mp						 deploys MP
.PHONY: tsb_mp
tsb_mp:
  ## working around the issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/2602
	terraform apply -auto-approve -target=module.azure_k8s -target=module.aws_base -target=module.aws_jumpbox 
	terraform apply -auto-approve -target=module.tsb_mp.kubectl_manifest.manifests_certs
	terraform apply -auto-approve -target=module.tsb_mp
	terraform apply -auto-approve -target=module.aws_dns -var=cluster_id=0 -var=cloud=azure

## tsb_fqdn					 creates TSB MP FQDN
.PHONY: tsb_fqdn
tsb_fqdn:
	terraform apply -auto-approve -target=module.aws_dns -var=cluster_id=0 -var=cloud=azure

## tsb_cp	cluster_id=1 cloud=azure		 onboards CP on AKS cluster with ID=1 
.PHONY: tsb_cp
tsb_cp:
	@echo cluster_id is ${cluster_id} 
	@echo cloud is ${cloud}
	terraform state list | grep "^module.cert-manager" | grep -v data | tr -d ':' | xargs -I '{}' terraform taint {}
	terraform taint -allow-missing "module.tsb_cp.null_resource.jumpbox_tctl"
  ## working around the issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/2602
	terraform apply -auto-approve -target=module.azure_k8s -target=module.aws_base -target=module.aws_jumpbox  
	terraform apply -auto-approve -target=module.cert-manager -var=cluster_id=${cluster_id} -var=cloud=${cloud}
	terraform apply -auto-approve -target=module.tsb_cp -var=cluster_id=${cluster_id} -var=cloud=${cloud}

## argocd cluster_id=1 cloud=azure		 onboards ArgoCD on AKS cluster with ID=1 
.PHONY: argocd
argocd:
	@echo cluster_id is ${cluster_id} 
	@echo cloud is ${cloud}
  ## working around the issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/2602
	terraform apply -auto-approve -target=module.azure_k8s -target=module.aws_base -target=module.aws_jumpbox 
	terraform apply -auto-approve -target=module.argocd -var=cluster_id=${cluster_id} -var=cloud=${cloud}

.PHONY: keycloak
keycloak:
  ## working around the issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/2602
	terraform apply -auto-approve -target=module.azure_k8s -target=module.aws_base -target=module.aws_jumpbox 
	terraform apply -auto-approve -target=module.keycloak-helm -var=cluster_id=0

.PHONY: app_bookinfo
app_bookinfo:
	@echo cluster_id is ${cluster_id} 
	@echo cloud is ${cloud}
	terraform state list | grep "^module.app_bookinfo" | grep -v data | tr -d ':' | xargs -I '{}' terraform taint {}
  ## working around the issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/2602
	terraform apply -auto-approve -target=module.azure_k8s -target=module.aws_base -target=module.aws_jumpbox 
	terraform apply -auto-approve -target=module.app_bookinfo -var=cluster_id=${cluster_id} -var=cloud=${cloud}

.PHONY: azure_oidc
azure_oidc:
	terraform apply -auto-approve -target=module.azure_oidc

## destroy					 destroy the environment
.PHONY: destroy
destroy:
	terraform destroy -refresh=false -target=module.aws_dns
	terraform destroy -refresh=false -target=module.azure_k8s
	terraform destroy -refresh=false -target=module.azure_base
	terraform destroy -refresh=false -target=module.azure_jumpbox
	terraform destroy -refresh=false 
	terraform destroy 