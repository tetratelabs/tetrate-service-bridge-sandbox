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

##@ Infrastructure provisioning

.PHONY: k8s
k8s: azure_k8s aws_k8s gcp_k8s  ## Deploys k8s cluster for MP and N-number of CPs(*) 

.PHONY: azure_k8s
azure_k8s:  ## Deploys azure k8s cluster for MP and N-number of CPs(*) leveraging AKS
	@/bin/sh -c '\
		index=0; \
		name_prefix=`jq -r '.name_prefix' terraform.tfvars.json`; \
		jq -r '.azure_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		cluster_name="aks-$$name_prefix-$$region-$$index"; \
		echo "cloud=azure region=$$region cluster_id=$$index cluster_name=$$cluster_name"; \
		cd "infra/azure"; \
		terraform workspace new azure-$$index-$$region; \
		terraform workspace select azure-$$index-$$region; \
		terraform init; \
		terraform apply ${terraform_apply_args} -target module.azure_base -var-file="../../terraform.tfvars.json" -var=azure_k8s_region=$$region -var=cluster_name=$$cluster_name -var=cluster_id=$$index; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=azure_k8s_region=$$region -var=cluster_name=$$cluster_name -var=cluster_id=$$index; \
		terraform output ${terraform_output_args} | jq . > ../../outputs/terraform_outputs/terraform-azure-$$cluster_name-$$index.json; \
		terraform workspace select default; \
		index=$$((index+1)); \
		cd "../.."; \
		done; \
		'

.PHONY: aws_k8s
aws_k8s:  ## Deploys EKS K8s cluster (CPs only)
	@/bin/sh -c '\
		index=0; \
		name_prefix=`jq -r '.name_prefix' terraform.tfvars.json`; \
		jq -r '.aws_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		cluster_name="eks-$$name_prefix-$$region-$$index"; \
		echo "cloud=aws region=$$region cluster_id=$$index cluster_name=$$cluster_name"; \
		cd "infra/aws"; \
		terraform workspace new aws-$$index-$$region; \
		terraform workspace select aws-$$index-$$region; \
		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=aws_k8s_region=$$region -var=cluster_name=$$cluster_name -var=cluster_id=$$index; \
		terraform output ${terraform_output_args} | jq . > ../../outputs/terraform_outputs/terraform-aws-$$cluster_name-$$index.json; \
		terraform workspace select default; \
		index=$$((index+1)); \
		cd "../.."; \
		done; \
		'

.PHONY: gcp_k8s
gcp_k8s:  ## Deploys GKE K8s cluster (CPs only)
	@/bin/sh -c '\
		index=0; \
		name_prefix=`jq -r '.name_prefix' terraform.tfvars.json`; \
		jq -r '.gcp_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		cluster_name="gke-$$name_prefix-$$region-$$index"; \
		echo "cloud=gcp region=$$region cluster_id=$$index cluster_name=$$cluster_name"; \
		cd "infra/gcp"; \
		terraform workspace new gcp-$$index-$$region; \
		terraform workspace select gcp-$$index-$$region; \
		terraform init; \
		terraform apply ${terraform_apply_args} -target module.gcp_base -var-file="../../terraform.tfvars.json" -var=gcp_k8s_region=$$region -var=cluster_name=$$cluster_name -var=cluster_id=$$index; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=gcp_k8s_region=$$region -var=cluster_name=$$cluster_name -var=cluster_id=$$index; \
		terraform output ${terraform_output_args} | jq . > ../../outputs/terraform_outputs/terraform-gcp-$$cluster_name-$$index.json; \
		terraform workspace select default; \
		index=$$((index+1)); \
		cd "../.."; \
		done; \
		'

##@ TSB installation

.PHONY: tsb
tsb: k8s tsb_mp tsb_cp  ## Deploys a full environment (Infra+MP+CP)
	@echo "Magic is on the way..."

.PHONY: tsb_mp
tsb_mp:  ## Deploys the TSB Management Plane
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s
	@echo "Deploying TSB Management Plane..."
	@/bin/sh -c '\
		cloud=`jq -r '.tsb_mp.cloud' terraform.tfvars.json`; \
		cd "tsb/mp"; \
		terraform workspace select default; \
		terraform init; \
		terraform apply ${terraform_apply_args} -target=module.cert-manager -target=module.es -target="data.terraform_remote_state.infra" -var-file="../../terraform.tfvars.json"; \
		terraform apply ${terraform_apply_args} -target=module.tsb_mp.kubectl_manifest.manifests_certs -target="data.terraform_remote_state.infra" -var-file="../../terraform.tfvars.json"; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json"; \
		terraform output ${terraform_output_args} | jq . > ../../outputs/terraform_outputs/terraform-tsb-mp.json; \
		fqdn=`jq -r '.tsb_fqdn' ../../terraform.tfvars.json`; \
		address=`jq -r "if .ingress_ip.value != \"\" then .ingress_ip.value else .ingress_hostname.value end" ../../outputs/terraform_outputs/terraform-tsb-mp.json`; \
		terraform -chdir=../fqdn/$$cloud init; \
		terraform -chdir=../fqdn/$$cloud apply ${terraform_apply_args} -var-file="../../../terraform.tfvars.json" -var=address=$$address -var=fqdn=$$fqdn; \
		terraform workspace select default; \
		cd "../.."; \
		'

.PHONY: tsb_cp
tsb_cp: tsb_cp_gcp tsb_cp_aws tsb_cp_azure  ## Onboards Control Plane clusters
tsb_cp_%:
	@echo "Onboarding clusters, i.e. TSB CP rollouts..."
	@$(MAKE) $*_k8s
	@/bin/sh -c '\
		index=0; \
		jq -r '.$*_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		echo "cloud=$* region=$$region cluster_id=$$index"; \
		cd "tsb/cp"; \
		terraform workspace new $*-$$index-$$region; \
		terraform workspace select $*-$$index-$$region; \
		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=cloud=$* -var=cluster_id=$$index; \
		terraform workspace select default; \
		index=$$((index+1)); \
		cd "../.."; \
		done; \
		'

##@ Add-on installation

.PHONY: monitoring
monitoring:  ## Deploys the TSB monitoring stack
	@echo "Deploying TSB monitoring stack..."
	@$(MAKE) k8s
	@/bin/sh -c '\
		cd "addons/monitoring"; \
		terraform workspace select default; \
		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json"; \
		terraform output ${terraform_output_args} | jq . > ../../outputs/terraform_outputs/terraform-monitoring.json; \
		terraform workspace select default; \
		cd "../.."; \
		'

.PHONY: argocd
argocd: argocd_gcp argocd_aws argocd_azure  ## Deploys ArgoCD
argocd_%:
	@echo "Deploying ArgoCD..."
	@$(MAKE) $*_k8s
	@/bin/sh -c '\
		index=0; \
		jq -r '.$*_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		echo "cloud=$* region=$$region cluster_id=$$index"; \
		cd "addons/argocd"; \
		terraform workspace new $*-$$index-$$region; \
		terraform workspace select $*-$$index-$$region; \
		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=cloud=$* -var=cluster_id=$$index; \
		terraform output ${terraform_output_args} | jq . > ../../outputs/terraform_outputs/terraform-argocd-$*-$$index.json; \
		terraform workspace select default; \
		index=$$((index+1)); \
		cd "../.."; \
		done; \
		'

.PHONY: external-dns
external-dns: external-dns_gcp  ## Deploys External DNS
external-dns_%:
	@echo "Deploying External DNS..."
	@$(MAKE) $*_k8s
	@/bin/sh -c '\
		cd "addons/external-dns/$*/credentials"; \
		terraform workspace select default; \
		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../../../terraform.tfvars.json"; \
		cd "../../../.."; \
		index=0; \
		jq -r '.$*_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		echo "cloud=$* region=$$region cluster_id=$$index"; \
		cd "addons/external-dns/$*"; \
		terraform workspace new $*-$$index-$$region; \
		terraform workspace select $*-$$index-$$region; \
		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../../terraform.tfvars.json" -var=cluster_id=$$index; \
		terraform workspace select default; \
		index=$$((index+1)); \
		cd "../../.."; \
		done; \
		'

##@ Clenaup

.PHONY: destroy
destroy: destroy_remote destroy_local  ## Destroy the environment and the local Terraform state and cache

.PHONY: destroy_remote
destroy_remote:  ## Destroy the environment
	@/bin/sh -c '\
		cloud=`jq -r '.tsb_mp.cloud' terraform.tfvars.json`; \
		fqdn=`jq -r '.tsb_fqdn' terraform.tfvars.json`; \
		address=`jq -r "if .ingress_ip.value != \"\" then .ingress_ip.value else .ingress_hostname.value end" outputs/terraform_outputs/terraform-tsb-mp.json`; \
		cd "tsb/fqdn/$$cloud"; \
		terraform destroy ${terraform_apply_args} -var-file="../../../terraform.tfvars.json" -var=address=$$address -var=fqdn=$$fqdn; \
		rm -rf terraform.tfstate.d/; \
		rm -rf terraform.tfstate; \
		cd "../../.."; \
		'
	@$(MAKE) destroy_gcp destroy_aws destroy_azure

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
		terraform destroy ${terraform_destroy_args} -var-file="../../terraform.tfvars.json" -var=$*_k8s_region=$$region -var=cluster_id=$$index; \
		terraform workspace select default; \
		terraform workspace delete ${terraform_workspace_args} $*-$$index-$$region; \
		index=$$((index+1)); \
		cd "../.."; \
		done; \
		'

.PHONY: destroy_tfstate
destroy_tfstate:
	find . -name terraform.tfstate.d -exec rm -rf {} +
	find . -name terraform.tfstate -delete

.PHONY: destroy_tfcache
destroy_tfcache:
	find . -name .terraform -exec rm -rf {} +
	find . -name .terraform.lock.hcl -delete

.PHONY: destroy_outputs
destroy_outputs:
	rm -f outputs/*-kubeconfig.sh outputs/*-jumpbox.sh outputs/*-kubeconfig outputs/*.jwk outputs/*.pem
	rm -f outputs/terraform_outputs/*.json

##@ Others

.PHONY: help
help: Makefile  ## Prints this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} \
			/^[.a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
			/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)
