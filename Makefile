# Copyright (c) Tetrate, Inc 2021 All Rights Reserved.
# 
# Default variables
cluster_id = 1
cloud = azure
# Functions
azure_jumpbox:
	terraform init
	terraform apply -auto-approve -target=module.azure_base
	terraform apply -auto-approve -target=module.azure_jumpbox
azure_k8s:
	terraform init
	terraform apply -auto-approve -target=module.azure_base
	terraform apply -auto-approve -target=module.azure_jumpbox
	terraform apply -auto-approve -target=module.azure_k8s
tsb_deps:
	terraform init
	terraform apply -auto-approve -target=module.cert-manager -var=cluster_id=0
	terraform apply -auto-approve -target=module.es
tsb_mp:
	terraform init
	terraform apply -auto-approve -target=module.tsb_mp.kubectl_manifest.manifests_certs
	terraform apply -auto-approve -target=module.tsb_mp
	terraform apply -auto-approve -target=module.aws_dns
tsb_fqdn:
	terraform apply -auto-approve -target=module.aws_dns
tsb_cp:
	@echo cluster_id is ${cluster_id} 
	@echo cloud is ${cloud}
	terraform init
	terraform taint -allow-missing "module.cert-manager"
	terraform apply -auto-approve -target=module.cert-manager -var=cluster_id=${cluster_id} 
	terraform taint -allow-missing "module.tsb_cp.null_resource.jumpbox_tctl"
	terraform apply -auto-approve -target=module.tsb_cp -var=cluster_id=${cluster_id} -var=cloud=${cloud}
argocd:
	@echo cluster_id is ${cluster_id} 
	@echo cloud is ${cloud}
	terraform apply -auto-approve -target=module.argocd -var=cluster_id=${cluster_id} -var=cloud=${cloud}
keycloak:
	terraform apply -auto-approve -target=module.keycloak-helm -var=cluster_id=0
app_bookinfo:
	@echo cluster_id is ${cluster_id} 
	@echo cloud is ${cloud}
	terraform init
	terraform taint -allow-missing "module.app_bookinfo"
	terraform apply -auto-approve -target=module.app_bookinfo -var=cluster_id=${cluster_id} -var=cloud=${cloud}
azure_oidc:
	terraform init
	terraform apply -auto-approve -target=module.azure_oidc
destroy:
	terraform destroy -refresh=false -target=module.aws_dns
	terraform destroy -refresh=false -target=module.azure_k8s
	terraform destroy -refresh=false -target=module.azure_base
	terraform destroy -refresh=false -target=module.azure_jumpbox
	terraform destroy -refresh=false 
	terraform destroy 