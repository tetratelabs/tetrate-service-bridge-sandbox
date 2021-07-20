# Copyright (c) Tetrate, Inc 2021 All Rights Reserved.
aks:
	terraform init
	terraform validate
	terraform apply -auto-approve -target=module.azure_k8s
tsb_deps:
	terraform init
	terraform validate
	terraform apply -auto-approve -target=module.cert-manager
	terraform apply -auto-approve -target=module.elastic
tsb_mp:
	terraform init
	terraform validate
	terraform apply -auto-approve -target=module.tsb_mp.null_resource.tctl_managementplane
	terraform apply -auto-approve -target=module.tsb_mp.null_resource.tctl_managementplanesecrets
	terraform apply -auto-approve -target=module.tsb_mp
tsb_cp:
	terraform init
	terraform validate
	terraform apply -auto-approve -target=module.tsb_cp.null_resource.tctl_controlplane
	terraform apply -auto-approve -target=module.tsb_cp
azure_oidc:
	terraform init
	terraform validate
	terraform apply -auto-approve -target=module.azure_oidc
app_bookinfo:
	terraform init
	terraform validate
	terraform apply -auto-approve -target=module.app_bookinfo
destroy:
	terraform validate
	terraform destroy -auto-approve -target=module.azure_k8s
	terraform destroy -auto-approve -target=module.azure_base
	terraform destroy -auto-approve -target=module.azure_jumpbox
	terraform destroy -auto-approve