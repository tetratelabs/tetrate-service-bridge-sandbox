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
    "k8s_clusters": {
        "aws": [
        ],
        "azure": [
        ],
        "gcp": [
            {
                "region": "us-central1",
                "tetrate": {
                    "management_plane": true
                }
            },
            {
                "region": "us-west1",
                "tetrate": {
                    "control_plane": true
                }
            }
        ]
    },
    "name_prefix": "",
    "tags": {
       "tetrate_owner": "username",
       "tetrate_team": "function:team"
    },
    "tetrate": {
        "fqdn": "",
        "image_sync_apikey": "", 
        "image_sync_username": "",
        "organization": "tetrate",
        "version": "1.6.0-dev",
        "helm_repository": "",
        "helm_username": "",
        "helm_password": "",
        "password": "Tetrate123"
    }
}
```
