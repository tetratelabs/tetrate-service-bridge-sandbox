# Copyright (c) Tetrate, Inc 2021 All Rights Reserved.

# Environment configuration
dry_run     ?= true
tfvars_json ?= terraform.tfvars.json

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
	@/bin/sh -c "export TFVARS_JSON="${tfvars_json}" && ./make/variables.sh"
	@echo "Please refer to the latest instructions and terraform.tfvars.json file format at https://github.com/tetrateio/tetrate-service-bridge-sandbox#usage"


.PHONY: k8s
k8s: aws_k8s azure_k8s gcp_k8s  ## Deploys cloud infra and k8s clusters for MP and N-number of CPs
%_k8s: init
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/infra.sh $*_k8s'


.PHONY: k8s_auth
k8s_auth: k8s_auth_aws k8s_auth_azure k8s_auth_gcp   ## Refreshes k8s auth token
k8s_auth_%:
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/k8s_auth.sh k8s_auth_$*'



.PHONY: tsb_mp
tsb_mp:  ## Deploys MP
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth
	@echo "Deploying TSB Management Plane..."
	@/bin/sh -c '\
		set -e; \
		cloud=`jq -r '.tsb_mp.cloud' terraform.tfvars.json`; \
		dns_provider=`jq -r '.dns_provider' terraform.tfvars.json`; \
		[ "$$dns_provider" == "null" ] && dns_provider=`jq -r '.tsb_fqdn' terraform.tfvars.json | cut -d"." -f2 | sed 's/sandbox/gcp/g'`; \
		cd "tsb/mp"; \
		terraform workspace select default; \
		terraform init; \
		terraform apply ${terraform_apply_args} -target=module.cert-manager -target=module.es -target="data.terraform_remote_state.infra" -var-file="../../terraform.tfvars.json"; \
		terraform apply ${terraform_apply_args} -target=module.tsb_mp.kubectl_manifest.manifests_certs -target="data.terraform_remote_state.infra" -var-file="../../terraform.tfvars.json"; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json"; \
		terraform output ${terraform_output_args} | jq . > ../../outputs/terraform_outputs/terraform-tsb-mp.json; \
		fqdn=`jq -r '.tsb_fqdn' ../../terraform.tfvars.json`; \
		address=`jq -r "if .ingress_ip.value != \"\" then .ingress_ip.value else .ingress_hostname.value end" ../../outputs/terraform_outputs/terraform-tsb-mp.json`; \
		terraform -chdir=../fqdn/$$dns_provider init; \
		terraform -chdir=../fqdn/$$dns_provider apply ${terraform_apply_args} -var-file="../../../terraform.tfvars.json" -var=address=$$address -var=fqdn=$$fqdn; \
		terraform workspace select default; \
		cd "../.."; \
		'

.PHONY: tsb_cp
tsb_cp: tsb_cp_aws tsb_cp_azure tsb_cp_gcp ## Onboards Control Plane clusters
tsb_cp_%:
	@echo "Onboarding clusters, i.e. TSB CP rollouts..."
	@$(MAKE) k8s_auth_$*
	@/bin/sh -c '\
		set -e; \
		index=0; \
		jq -r '.$*_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		echo "cloud=$* region=$$region cluster_id=$$index"; \
		cd "tsb/cp"; \
		terraform workspace new $*-$$index-$$region || true; \
		terraform workspace select $*-$$index-$$region; \
		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=cloud=$* -var=cluster_id=$$index; \
		terraform workspace select default; \
		index=$$((index+1)); \
		cd "../.."; \
		done; \
		'

.PHONY: tsb
tsb: k8s tsb_mp tsb_cp  ## Deploys a full environment (MP+CP)
	@echo "Magic is on the way..."

.PHONY: argocd
argocd: argocd_aws argocd_azure argocd_gcp ## Deploys ArgoCD
argocd_%:
	@echo "Deploying ArgoCD..."
	@$(MAKE) k8s_auth_$*
	@/bin/sh -c '\
		set -e; \
		index=0; \
		jq -r '.$*_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		echo "cloud=$* region=$$region cluster_id=$$index"; \
		cd "addons/argocd"; \
		terraform workspace new $*-$$index-$$region || true; \
		terraform workspace select $*-$$index-$$region; \
		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=cloud=$* -var=cluster_id=$$index; \
		terraform output ${terraform_output_args} | jq . > ../../outputs/terraform_outputs/terraform-argocd-$*-$$index.json; \
		terraform workspace select default; \
		index=$$((index+1)); \
		cd "../.."; \
		done; \
		'

.PHONY: fluxcd
fluxcd: fluxcd_aws fluxcd_azure fluxcd_gcp ## Deploys ArgoCD
fluxcd_%:
	@echo "Deploying FluxCD..."
	@$(MAKE) k8s_auth_$*
	@/bin/sh -c '\
		set -e; \
		index=0; \
		jq -r '.$*_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		echo "cloud=$* region=$$region cluster_id=$$index"; \
		cd "addons/fluxcd"; \
		terraform workspace new $*-$$index-$$region || true; \
		terraform workspace select $*-$$index-$$region; \
		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=cloud=$* -var=cluster_id=$$index; \
		terraform output ${terraform_output_args} | jq . > ../../outputs/terraform_outputs/terraform-fluxcd-$*-$$index.json; \
		terraform workspace select default; \
		index=$$((index+1)); \
		cd "../.."; \
		done; \
		'

.PHONY: tsb-monitoring
tsb-monitoring:  ## Deploys the TSB monitoring stack
	@echo "Deploying TSB monitoring stack..."
	@$(MAKE) k8s_auth
	@/bin/sh -c '\
		set -e; \
		cd "addons/tsb-monitoring"; \
		terraform workspace select default; \
		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json"; \
		terraform output ${terraform_output_args} | jq . > ../../outputs/terraform_outputs/terraform-tsb-monitoring.json; \
		terraform workspace select default; \
		cd "../.."; \
		'

.PHONY: external-dns
external-dns: external-dns_aws external-dns_azure external-dns_gcp ## Deploys external-dns
external-dns_%:
	@echo "Deploying external-dns..."
	@$(MAKE) k8s_auth_$*
	@/bin/sh -c '\
		set -e; \
		index=0; \
		jq -r '.$*_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		echo "cloud=$* region=$$region cluster_id=$$index"; \
		cd "addons/$*/external-dns"; \
		terraform workspace new $*-$$index-$$region || true; \
		terraform workspace select $*-$$index-$$region; \
		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../../terraform.tfvars.json" -var=cloud=$* -var=cluster_id=$$index; \
		terraform workspace select default; \
		index=$$((index+1)); \
		cd "../../.."; \
		done; \
		'

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


.PHONY: destroy_aws
destroy_aws:  ## Destroy aws infra and eks k8s clusters
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/infra.sh destroy_aws'

.PHONY: destroy_azure
destroy_azure:  ## Destroy azure infra and aks k8s clusters
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/infra.sh destroy_azure'

.PHONY: destroy_gcp
destroy_gcp:  ## Destroy gcp infra and gke k8s clusters
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/infra.sh destroy_gcp'

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
