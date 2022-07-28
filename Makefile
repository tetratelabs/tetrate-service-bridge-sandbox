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
.PHONY: loop1
loop1:
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

## init					 	 terraform init
.PHONY: init
init:
	@echo "Please refer to the latest instructions and terraform.tfvars file format at https://github.com/smarunich/tetrate-service-bridge-sandbox#usage"
	terraform init
	terraform apply -target=google_project.tsb

## azure_jumpbox					 deploys jumpbox, pushes tsb repo to acr
.PHONY: azure_jumpbox
azure_jumpbox: init
	terraform apply ${terraform_apply_args} -target=module.azure_base -target=module.azure_jumpbox


## gcp_jumpbox					 deploys jumpbox, pushes tsb repo to gcr
.PHONY: gcp_jumpbox
gcp_jumpbox: init
	terraform apply ${terraform_apply_args} -target=module.gcp_base -target=module.gcp_jumpbox

## k8s						 deploys k8s cluster for MP and N-number of CPs(*) 
.PHONY: k8s
k8s: aws_k8s

## azure_k8s					 deploys azure k8s cluster for MP and N-number of CPs(*) leveraging AKS
.PHONY: azure_k8s
azure_k8s: init
	terraform apply ${terraform_apply_args} -target=module.azure_base
	terraform apply ${terraform_apply_args} -target=module.azure_jumpbox 
	terraform apply ${terraform_apply_args} -target=module.azure_k8s

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
	terraform apply ${terraform_apply_args} -target=module.gcp_base 
	terraform apply ${terraform_apply_args} -target=module.gcp_jumpbox 
	terraform apply ${terraform_apply_args} -target=module.gcp_k8s

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

## tsb_cp	cluster_id=1 cloud=azure		 onboards CP on AKS cluster with ID=1 
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

## argocd cluster_id=1 cloud=azure		 onboards ArgoCD on AKS cluster with ID=1 
.PHONY: argocd
argocd:
	@echo "Deploying ArgoCD to ${cloud} cluster with cluster_id=${cluster_id}"
	terraform apply ${terraform_apply_args} -target=module.argocd -var=cluster_id=${cluster_id} -var=cloud=${cloud}

.PHONY: keycloak
keycloak:
	terraform apply ${terraform_apply_args} -target=module.keycloak-helm -var=cluster_id=0

.PHONY: app_bookinfo
app_bookinfo:
	@echo "Deploying bookinfo application to ${cloud} cluster with cluster_id=${cluster_id}"
	terraform state list | grep "^module.app_bookinfo" | grep -v data | tr -d ':' | xargs -I '{}' terraform taint {}
	terraform apply ${terraform_apply_args} -target=module.app_bookinfo -var=cluster_id=${cluster_id} -var=cloud=${cloud}

.PHONY: azure_oidc
azure_oidc:
	terraform apply ${terraform_apply_args} -target=module.azure_oidc

.PHONY: fast_track
fast_track_tsb:
	make k8s
	make tsb_mp
	make tsb_cp cluster_id=0 cloud=azure || true
	make tsb_cp cluster_id=1 cloud=azure || true
	make tsb_cp cluster_id=0 cloud=aws || true
	make tsb_cp cluster_id=1 cloud=aws || true
	make tsb_cp cluster_id=0 cloud=gcp || true
	make tsb_cp cluster_id=1 cloud=gcp || true

fast_track_argo:
	make argocd cluster_id=0 cloud=azure || true
	make argocd cluster_id=1 cloud=azure || true
	make argocd cluster_id=0 cloud=aws || true
	make argocd cluster_id=0 cloud=gcp || true

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
	terraform destroy ${terraform_destroy_args} -refresh=false -target=module.aws_k8s 
	terraform destroy ${terraform_destroy_args} -refresh=false -target=module.aws_jumpbox  -target=module.aws_base
	terraform destroy ${terraform_destroy_args} -refresh=false -target=module.gcp_k8s  
	terraform destroy ${terraform_destroy_args} -refresh=false -target=module.gcp_jumpbox -target=module.gcp_base
	terraform destroy ${terraform_destroy_args} -refresh=false -target=module.azure_k8s 
	terraform destroy ${terraform_destroy_args} -refresh=false -target=module.azure_jumpbox -target=module.azure_base
	terraform destroy ${terraform_destroy_args} -refresh=false 
	terraform destroy ${terraform_destroy_args}
