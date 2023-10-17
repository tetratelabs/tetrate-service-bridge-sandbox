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

# Terraform command line variables
export TERRAFORM_APPLY_ARGS="-compact-warnings -auto-approve"
export TERRAFORM_DESTROY_ARGS="-compact-warnings -auto-approve"
export TERRAFORM_WORKSPACE_ARGS="-force"
export TERRAFORM_OUTPUT_ARGS="-json"

# Required tfvars.json variables
#   format: "<parameter>:<allowed_value1>,<allowed_value2>,..."
export REQUIRED_VARS=(
  "aws_k8s_regions:"
  "azure_k8s_regions:"
  "dns_provider:aws,azure,gcp"
  "gcp_k8s_regions:"
  "name_prefix:"
  "tetrate_owner:"
  "tetrate_team:"
  "tsb_fqdn:"
  "tsb_image_sync_apikey:"
  "tsb_image_sync_username:"
  "tsb_mp.cloud:aws,azure,gcp"
  "tsb_mp.cluster_id:"
  "tsb_org:"
  "tsb_password:"
  "tsb_version:"
  )

# This function is used to validate the structure of a JSON input based on a specific schema.
# It checks for the presence and validity of the fields in the provided JSON.
#
# Parameters:
#   $1 - The path to the JSON file to be validated.
#
# Usage: validate_input "/path/to/your/json/file.tfvars.json"
function validate_input() {
  [[ -z "${1}" ]] && print_error "Please provide tfvar.json file as 1st argument" && return 1 || local json_tfvars="${1}" ;

  # Check if the file exists
  if [[ ! -f "${json_tfvars}" ]]; then
    print_error "File '${json_tfvars}' does not exist."
    exit 1
  fi

  # Validate individual fields
  for item in "${REQUIRED_VARS[@]}"; do
    variable="${item%%:*}" ; # Extracts everything before the colon
    allowed_values="${item##*:}" ; # Extracts everything after the colon
    current_value=$(jq -r ".${variable}" "${json_tfvars}")
    if [[ -z "${current_value}" ]]; then
      print_error "Missing ${variable} in the JSON.";
      exit 1
    fi
    if [[ -n "${allowed_values}" ]] && ! [[ "${allowed_values}" =~ .*"${current_value}".* ]] ; then
      print_error "Validation error: ${variable} is set to the incorrect value: '${current_value}', allowed values: '${allowed_values}'\n";
      exit 1
    fi
  done

  print_info "JSON structure of '${json_tfvars}' is valid."
}

# Validate input values
validate_input "${TFVARS_JSON}"

# Parse tfvars.json and export variables
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
