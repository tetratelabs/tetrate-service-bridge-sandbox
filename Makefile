# Copyright (c) Tetrate, Inc 2021 All Rights Reserved.

# Default variables
terraform_apply_args = -compact-warnings -auto-approve
terraform_destroy_args = -compact-warnings -auto-approve 
terraform_workspace_args = -force
terraform_output_args = -json

# Functions
.DEFAULT_GOAL := help

.PHONY: all
all: tsb

.PHONY: help
help: Makefile ## This help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n"} \
			/^[.a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36mmake %-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: init
init:  ## Terraform init
	@echo "Please refer to the latest instructions and terraform.tfvars.json file format at https://github.com/tetrateio/tetrate-service-bridge-sandbox#usage"

.PHONY: validate
validate:  ## Validate terraform.tfvars.json
	@/bin/bash make.sh validate

.PHONY: k8s
k8s: ## Deploys k8s cluster for MP and N-number of CPs(*) 
	@echo "Deploying k8s clusters..."
	@/bin/bash make.sh k8s_clusters

.PHONY: k8s_auth
k8s_auth: ## Refreshes k8s auth token
	@echo "Refreshing k8s auths..."
	@/bin/bash make.sh k8s_auths

.PHONY: tsb_mp
tsb_mp: ## Deploys MP
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth
	@echo "Deploying TSB Management Plane..."
	@/bin/bash make.sh tsb_mp

.PHONY: tsb_cp
tsb_cp: ## Onboards Control Plane clusters
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth
	@echo "Deploying TSB Control Planes..."
	@/bin/bash make.sh tsb_cps

.PHONY: tsb
tsb: k8s tsb_mp tsb_cp  ## Deploys a full environment (MP+CP)
	@echo "Magic is on the way..."

.PHONY: argocd
argocd: argocd_aws argocd_azure argocd_gcp ## Deploys ArgoCD
argocd_%:
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth
	@echo "Deploying ArgoCD..."
	@/bin/bash make.sh argo_cd

.PHONY: fluxcd
fluxcd: ## Deploys ArgoCD
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth_$*
	@echo "Deploying FluxCD..."
	@/bin/bash make.sh flux_cd

.PHONY: tsb-monitoring
tsb-monitoring:  ## Deploys the TSB monitoring stack
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth
	@echo "Deploying TSB monitoring stack..."
	@/bin/bash make.sh tsb_monitoring

.PHONY: external-dns
external-dns: external-dns_aws external-dns_azure external-dns_gcp ## Deploys external-dns
external-dns_%:
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth
	@echo "Deploying external-dns..."
	@/bin/bash make.sh external_dns

destroy_external-dns: destroy_external-dns_aws destroy_external-dns_azure destroy_external-dns_gcp ## Destroys external-dns
destroy_external-dns_%:
	@echo "Deploying external-dns..."
	@$(MAKE) k8s_auth_$*
	@/bin/sh -c '\
		index=0; \
		jq -r '.$*_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		echo "cloud=$* region=$$region cluster_id=$$index"; \
		cd "addons/$*/external-dns"; \
		terraform workspace new $*-$$index-$$region || true; \
		terraform workspace select $*-$$index-$$region; \
		terraform init; \
		terraform destroy ${terraform_apply_args} -var-file="../../../terraform.tfvars.json" -var=cloud=$* -var=cluster_id=$$index; \
		terraform workspace select default; \
		index=$$((index+1)); \
		cd "../../.."; \
		done; \
		'

.PHONY: destroy
destroy: destroy_remote destroy_local

.PHONY: destroy_remote
destroy_remote:  ## Destroy the environment
	@/bin/sh -c '\
		cloud=`jq -r '.tsb_mp.cloud' terraform.tfvars.json`; \
		fqdn=`jq -r '.tsb_fqdn' terraform.tfvars.json`; \
		address=`jq -r "if .ingress_ip.value != \"\" then .ingress_ip.value else .ingress_hostname.value end" outputs/terraform_outputs/terraform-tsb-mp.json`; \
		cd "tsb/fqdn/$$cloud"; \
		terraform init; \
		terraform destroy ${terraform_apply_args} -var-file="../../../terraform.tfvars.json" -var=address=$$address -var=fqdn=$$fqdn; \
		rm -rf terraform.tfstate.d/; \
		rm -rf terraform.tfstate; \
		cd "../../.."; \
		'
	@$(MAKE) destroy_external-dns
	@$(MAKE) destroy_aws destroy_azure destroy_gcp

.PHONY: destroy_local
destroy_local:  ## Destroy the local Terraform state and cache
	@$(MAKE) destroy_tfstate
	@$(MAKE) destroy_tfcache
	@$(MAKE) destroy_outputs

destroy_%:
	@/bin/sh -c '\
		index=0; \
		name_prefix=`jq -r '.name_prefix' terraform.tfvars.json`; \
		jq -r '.$*_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		echo "cloud=$* region=$$region cluster_id=$$index"; \
		cd "infra/$*"; \
		terraform workspace select $*-$$index-$$region; \
		cluster_name=`terraform output cluster_name | jq . -r`; \
		terraform destroy ${terraform_destroy_args} -var-file="../../terraform.tfvars.json" -var=$*_k8s_region=$$region -var=cluster_id=$$index -var=cluster_name=$$cluster_name; \
		terraform workspace select default; \
		terraform workspace delete ${terraform_workspace_args} $*-$$index-$$region; \
		index=$$((index+1)); \
		cd "../.."; \
		done; \
		'

.PHONY: destroy_tfstate
destroy_tfstate:
	find . -name *tfstate* -exec rm -rf {} +

.PHONY: destroy_tfcache
destroy_tfcache:
	find . -name .terraform -exec rm -rf {} +
	find . -name .terraform.lock.hcl -delete

.PHONY: destroy_outputs
destroy_outputs:
	rm -f outputs/*-kubeconfig.sh outputs/*-jumpbox.sh outputs/*-kubeconfig outputs/*.jwk outputs/*.pem outputs/*-cleanup.sh
	rm -f outputs/terraform_outputs/*.json
