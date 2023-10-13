#!/usr/bin/env bash
#
# Helper script for global settings, environment file parsing and exposure.

BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR

# shellcheck source=/dev/null
source "${BASE_DIR}/helpers.sh"

# Check if TFVARS_JSON is not defined and exit.
if [ -z "${TFVARS_JSON}" ]; then
  print_error "TFVARS_JSON is not defined."
  exit 1
fi

# Check if the file pointed to by TFVARS_JSON does not exist and exit.
if [ ! -f "${TFVARS_JSON}" ]; then
  print_error "File '${TFVARS_JSON}' does not exist."
  exit 1
fi

# Output folder for deployment artifacts
export OUTPUTS_DIR=${BASE_DIR}/../outputs

# Terraform command line paramaters
export TERRAFORM_APPLY_ARGS="-compact-warnings -auto-approve"
export TERRAFORM_DESTROY_ARGS="-compact-warnings -auto-approve"
export TERRAFORM_WORKSPACE_ARGS="-force"
export TERRAFORM_OUTPUT_ARGS="-json"


# Parse tfvar.json and export variables
AWS_K8S_REGIONS=$(jq -r '.aws_k8s_regions | join(" ")' "${TFVARS_JSON}")
export AWS_K8S_REGIONS
AZURE_K8S_REGIONS=$(jq -r '.azure_k8s_regions | join(" ")' "${TFVARS_JSON}")
export AZURE_K8S_REGIONS
DNS_PROVIDER=$(jq -r '.dns_provider' "${TFVARS_JSON}")
export DNS_PROVIDER
GCP_K8S_REGIONS=$(jq -r '.gcp_k8s_regions | join(" ")' "${TFVARS_JSON}")
export GCP_K8S_REGIONS
NAME_PREFIX=$(jq -r '.name_prefix' "${TFVARS_JSON}")
export NAME_PREFIX
TETRATE_OWNER=$(jq -r '.tetrate_owner' "${TFVARS_JSON}")
export TETRATE_OWNER
TETRATE_TEAM=$(jq -r '.tetrate_team' "${TFVARS_JSON}")
export TETRATE_TEAM
TSB_FQDN=$(jq -r '.tsb_fqdn' "${TFVARS_JSON}")
export TSB_FQDN
TSB_IMAGE_SYNC_APIKEY=$(jq -r '.tsb_image_sync_apikey' "${TFVARS_JSON}")
export TSB_IMAGE_SYNC_APIKEY
TSB_IMAGE_SYNC_USERNAME=$(jq -r '.tsb_image_sync_username' "${TFVARS_JSON}")
export TSB_IMAGE_SYNC_USERNAME
TSB_MP_CLOUD=$(jq -r '.tsb_mp.cloud' "${TFVARS_JSON}")
export TSB_MP_CLOUD
TSB_MP_CLUSTER_ID=$(jq -r '.tsb_mp.cluster_id' "${TFVARS_JSON}")
export TSB_MP_CLUSTER_ID
TSB_ORG=$(jq -r '.tsb_org' "${TFVARS_JSON}")
export TSB_ORG
TSB_PASSWORD=$(jq -r '.tsb_password' "${TFVARS_JSON}")
export TSB_PASSWORD
TSB_VERSION=$(jq -r '.tsb_version' "${TFVARS_JSON}")
export TSB_VERSION
