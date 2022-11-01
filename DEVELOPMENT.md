# DEVELOPMENT.md

If you want to provision the latest master build you have to:

1. Provide ```tetrate_internal_cr``` variable as ```gcr.io/...```.
2. Provide ```tetrate_internal_cr_token``` variable using ```gcloud auth print-access-token```
3. Specify tsb_version that includes ```dev``` suffix, for example ```"tsb_version": "1.6.0-dev"

A complete reference example:

terraform.tfvars.json
```json
{
    "name_prefix": "r153sm1",
    "tsb_fqdn": "r153sm1.gcp.cx.tetrate.info",
    "tsb_version": "1.6.0-dev",
    "tsb_image_sync_username": "sergey-marunich",
    "tsb_image_sync_apikey": "4b15c33fd2b5e6c4e9efa6d637030dbdecd0b4c2",
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
    "tetrate_internal_cr": "gcr.io/tetrate-internal-containers",
    "tetrate_internal_cr_token": "ya29.a0Aa4xrXNvPOm1Kc69FxmVzg2uNZodXBJl5RSG6owW5l1v0_xxH6VIXa3Ty2zkPxMKGGMcXxk--sSxAQS2JKZ7B6rRWCHYE5nv2a5dskCZUz7s08G1HCCVV6A6SdU5bm814ONfYsx0OimI8V2GsAXKzMeFg-z1tO6JWnUEP2caCgYKATASARMSFQEjDvL9rOegk-w0KnaqOzfhiGH0Yg0174"
}
```