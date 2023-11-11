#!/usr/bin/env bash
#
# Global variables file
BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR
source "${BASE_DIR}/prints.sh"

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

# Terraform environment variables
if [ -z "${TF_LOG}" ]; then
  export TF_LOG="ERROR"
fi

# Required tfvars.json variables
#   format: "<parameter>:<allowed_value1>,<allowed_value2>,..."
export REQUIRED_VARS=(
  "k8s_clusters:"
  "name_prefix:"
  "tetrate.fqdn:"
  "tetrate.image_sync_apikey:"
  "tetrate.image_sync_username:"
  "tetrate.organization:"
  "tetrate.password:"
  "tetrate.version:"
)

# This function is used to validate the structure of a JSON input based on a specific schema. It checks for the presence and validity of the fields in the provided JSON.

function validate_input() {
  [[ -z "${1}" ]] && print_error "Please provide terraform.tfvars.json file as 1st argument" && return 1 || local tfvars_json="${1}" ;

  # Check if the file exists
  if [[ ! -f "${tfvars_json}" ]]; then
    print_error "File '${tfvars_json}' does not exist."
    exit 1
  fi

  # Validate individual fields
  for item in "${REQUIRED_VARS[@]}"; do
    variable="${item%%:*}" ; # Extracts everything before the colon
    allowed_values="${item##*:}" ; # Extracts everything after the colon
    current_value=$(jq -r ".${variable}" "${tfvars_json}")

    if [[ "${current_value}" == "null" ]]; then
        print_error "Missing ${variable} in the JSON.";
        exit 1;
    fi
    if [[ -n "${allowed_values}" ]] && ! [[ "${allowed_values}" =~ .*"${current_value}".* ]] ; then
        print_error "Validation error: ${variable} is set to the incorrect value: '${current_value}', allowed values: '${allowed_values}'\n";
        exit 1;
    fi
  done

  print_debug "JSON structure of '${tfvars_json}' is valid."
}

# Validate input values
validate_input "${TFVARS_JSON}"

# Parse tfvars.json and export variables
# DNS Provider variable
export DNS_PROVIDER=$(jq -r '.tetrate.dns_provider // .tetrate.fqdn | select(type == "string") | split(".") | if length > 1 then .[1] else .[0] end | select(. != null) | sub("sandbox"; "gcp")' "${TFVARS_JSON}")
AWS_K8S_REGIONS=$(jq -r '[.k8s_clusters.aws[].region] | join(" ")' "${TFVARS_JSON}")
export AWS_K8S_REGIONS
AZURE_K8S_REGIONS=$(jq -r '[.k8s_clusters.azure[].region] | join(" ")' "${TFVARS_JSON}")
export AZURE_K8S_REGIONS
GCP_K8S_REGIONS=$(jq -r '[.k8s_clusters.gcp[].region] | join(" ")' "${TFVARS_JSON}")
export GCP_K8S_REGIONS
NAME_PREFIX=$(jq -r '.name_prefix' "${TFVARS_JSON}")
export NAME_PREFIX

TETRATE_FQDN=$(jq -r '.tetrate.fqdn' "${TFVARS_JSON}")
export TETRATE_FQDN
TETRATE_IMAGE_SYNC_APIKEY=$(jq -r '.tetrate.image_sync_apikey' "${TFVARS_JSON}")
export TETRATE_IMAGE_SYNC_APIKEY
TETRATE_IMAGE_SYNC_USERNAME=$(jq -r '.tetrate.image_sync_username' "${TFVARS_JSON}")
export TETRATE_IMAGE_SYNC_USERNAME
TETRATE_ORGANIZATION=$(jq -r '.tetrate.organization' "${TFVARS_JSON}")
export TETRATE_ORGANIZATION
TETRATE_PASSWORD=$(jq -r '.tetrate.password' "${TFVARS_JSON}")
export TETRATE_PASSWORD
TETRATE_VERSION=$(jq -r '.tetrate.version' "${TFVARS_JSON}")
export TETRATE_VERSION
