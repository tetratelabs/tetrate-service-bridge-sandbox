# DEVELOPMENT.md

If you want to provision the latest master build you have to:

1. Provide ```tetrate_internal_cr``` variable as ```gcr.io/...```.
2. Provide ```tetrate_internal_cr_token``` variable using ```gcloud auth print-access-token```
3. Specify tsb_version that includes ```dev``` suffix, for example ```"tsb_version": "1.6.0-dev"

A complete reference example:

terraform.tfvars.json
```json
{
    "name_prefix": "",
    "tsb_fqdn": "",
    "tsb_version": "1.6.0-dev",
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
    "tetrate_internal_cr": "gcr.io/..",
    "tetrate_internal_cr_token": "..."
}
```