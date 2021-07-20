# Copyright (c) Tetrate, Inc 2021 All Rights Reserved.
aks:
	terraform init
	terraform validate
	terraform apply -auto-approve -target=module.azure_k8s
mp:
	terraform init
	terraform validate
	terraform apply -auto-approve -target=module.cert-manager
	terraform apply -auto-approve -target=module.elastic
	terraform apply -auto-approve -target=module.tsb_mp
cp:
	terraform init
	terraform validate
	terraform apply -auto-approve -target=module.tsb_cp
oidc:
	terraform init
	terraform validate
	terraform apply -auto-approve -target=module.azure_oidc
destroy:
	terraform validate
	terraform destroy -auto-approve -target=module.azure_k8s
	terraform destroy -auto-approve -target=module.azure_base
	terraform destroy -auto-approve -target=module.azure_jumpbox
	terraform destroy -auto-approve