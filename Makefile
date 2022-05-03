# Copyright (c) Tetrate, Inc 2021 All Rights Reserved.
jumpbox:
	terraform init
	terraform validate
	terraform apply -target=module.azure_jumpbox
aks:
	terraform init
	terraform validate
	terraform apply -target=module.azure_k8s
tsb_deps:
	terraform init
	terraform validate
	terraform apply -target=module.cert-manager
	terraform apply -target=module.es
tsb_mp:
	terraform init
	terraform validate
	terraform apply -target=module.tsb_mp
tsb_cp:
	terraform init
	terraform validate
	terraform apply -target=module.tsb_cp
azure_oidc:
	terraform init
	terraform validate
	terraform apply -target=module.azure_oidc
app_bookinfo:
	terraform init
	terraform validate
	terraform apply -target=module.app_bookinfo
destroy:
	terraform destroy 