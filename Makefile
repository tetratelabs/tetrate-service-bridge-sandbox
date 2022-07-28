# Copyright (c) Tetrate, Inc 2021 All Rights Reserved.
# 
# Default variables
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
	@echo "Please refer to the latest instructions and terraform.tfvars.json file format at https://github.com/smarunich/tetrate-service-bridge-sandbox#usage"

## k8s						 deploys k8s cluster for MP and N-number of CPs(*) 
.PHONY: k8s
k8s: aws_k8s azure_k8s gcp_k8s

## azure_k8s					 deploys azure k8s cluster for MP and N-number of CPs(*) leveraging AKS
.PHONY: azure_k8s
azure_k8s:
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
		terraform apply ${terraform_apply_args} -target module.azure_base -var-file="../../terraform.tfvars.json" -var=azure_k8s_region=$$region; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=azure_k8s_region=$$region -var=cluster_name=$$cluster_name; \
		terraform workspace select default; \
		cd "../.."; \
		let index++; \
		done; \
		'

## aws_k8s					 deploys EKS K8s cluster (CPs only)
.PHONY: aws_k8s
aws_k8s:
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
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=aws_k8s_region=$$region -var=cluster_name=$$cluster_name; \
		terraform workspace select default; \
		cd "../.."; \
		let index++; \
		done; \
		'

## gcp_k8s					 deploys GKE K8s cluster (CPs only)
.PHONY: gcp_k8s
gcp_k8s: init
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
		terraform apply ${terraform_apply_args} -target module.gcp_base -var-file="../../terraform.tfvars.json" -var=gcp_k8s_region=$$region; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=gcp_k8s_region=$$region -var=cluster_name=$$cluster_name; \
		terraform workspace select default; \
		cd "../.."; \
		let index++; \
		done; \
		'

## tsb_mp						 deploys MP
.PHONY: tsb_mp
tsb_mp: k8s
	@echo "Deploying TSB Management Plane..."
	@/bin/sh -c '\
		cd "tsb/mp"; \
		terraform workspace select default; \
 		terraform init; \
		terraform apply ${terraform_apply_args} -target=module.es -var-file="../../terraform.tfvars.json"; \
		terraform apply ${terraform_apply_args} -target=module.tsb_mp.kubectl_manifest.manifests_certs -var-file="../../terraform.tfvars.json"; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json"; \
		terraform workspace select default; \
		cd "../.."; \
		'

## tsb_cp	                       		 onboards CP on AKS cluster with ID=1 
.PHONY: tsb_cp
tsb_cp: tsb_mp
	@echo "Onboarding clusters, i.e. TSB CP rollouts..."
	@/bin/sh -c '\
		index=0; \
		jq -r '.aws_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		echo "cloud=aws region=$$region cluster_id=$$index"; \
		cd "tsb/cp"; \
		terraform workspace new aws-$$index-$$region; \
		terraform workspace select aws-$$index-$$region; \
 		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=cloud=aws -var=cluster_id=$$index; \
		terraform workspace select default; \
		cd "../.."; \
		let index++; \
		done; \
		'
	@/bin/sh -c '\
		index=0; \
		jq -r '.azure_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		echo "cloud=azure region=$$region cluster_id=$$index"; \
		cd "tsb/cp"; \
		terraform workspace new azure-$$index-$$region; \
		terraform workspace select azure-$$index-$$region; \
 		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=cloud=aws -var=cluster_id=$$index; \
		terraform workspace select default; \
		cd "../.."; \
		let index++; \
		done; \
		'
	@/bin/sh -c '\
		index=0; \
		jq -r '.gcp_k8s_regions[]' terraform.tfvars.json | while read -r region; do \
		echo "cloud=gcp region=$$region cluster_id=$$index"; \
		cd "tsb/cp"; \
		terraform workspace new gcp-$$index-$$region; \
		terraform workspace select gcp-$$index-$$region; \
 		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=cloud=aws -var=cluster_id=$$index; \
		terraform workspace select default; \
		cd "../.."; \
		let index++; \
		done; \
		'

.PHONY: tsb
tsb: tsb_cp
	@echo "Magic is on the way..."

## argocd                        		 onboards ArgoCD on AKS cluster with ID=1 
.PHONY: argocd
argocd:
	@echo "Deploying ArgoCD to ${cloud} cluster with cluster_id=${cluster_id}"
	terraform apply ${terraform_apply_args} -target=module.argocd -var=cluster_id=${cluster_id} -var=cloud=${cloud}

.PHONY: keycloak
keycloak:
	terraform apply ${terraform_apply_args} -target=module.keycloak-helm -var=cluster_id=0

## destroy					 destroy the environment
.PHONY: destroy
destroy:
	terraform destroy ${terraform_destroy_args} -refresh=false -target=module.aws_route53_register_fqdn