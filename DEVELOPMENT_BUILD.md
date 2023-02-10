# Provisioning development versions

If you want to provision the latest master build you have to:

1. Specify ```tsb_version``` that includes ```dev``` suffix, for example ```"tsb_version": "1.6.0-dev"```
2. Provide ```dev``` helm repo details such as ```tsb_helm_repository``` url, ```tsb_helm_repository_username``` and ```tsb_helm_repository_password```.
   Note: tetrands can use cloudsmith's repository in `tsb_helm_repository`.
3. Have the ```gcloud``` CLI installed on your machine. It will be used to get a token to access the internal releases registry.

A complete reference example:

`terraform.tfvars.json`
```json
{
    "name_prefix": "",
    "tsb_fqdn": "",
    "tsb_version": "1.6.0-dev",
    "tsb_helm_repository": "",
    "tsb_helm_repository_username": "",
    "tsb_helm_repository_password": "",
    "tsb_image_sync_username": "",
    "tsb_image_sync_apikey": "",
    "tsb_password": "Tetrate123",
    "tsb_mp": {
        "cloud": "gcp",
        "cluster_id": 0
    },
    "tsb_org": "tetrate",
    "aws_k8s_regions": [
    ],
    "azure_k8s_regions": [
    ],
    "gcp_k8s_regions": [
        "us-west1"
    ],
    "tetrate_owner": "username",
    "tetrate_team": "function:team"
}
```
