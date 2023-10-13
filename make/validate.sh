#!/usr/bin/env bash
#
# Helper script to validate terraform input (avoid disaster).
BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR

# shellcheck source=/dev/null
source "${BASE_DIR}/helpers.sh"
# shellcheck source=/dev/null
source "${BASE_DIR}/variables.sh"

ACTION=${1}

# Validate input values.
SUPPORTED_ACTIONS=("validate_input")
if ! [[ " ${SUPPORTED_ACTIONS[*]} " == *" ${ACTION} "* ]]; then
  print_error "Invalid action. Must be one of '${SUPPORTED_ACTIONS[*]}'."
  exit 1
fi

# This function provides help information for the script.
function help() {
  echo "Usage: ${0} <command> [options]"
  echo "Commands:"
  echo "  help            Display this help message."
  echo "  validate_input  Validate the structure of TFVAR JSON file."
}


# This function is used to validate the structure of a JSON input based on a specific schema.
# It checks for the presence and validity of the fields in the provided JSON.
#
# Parameters:
#   $1 - The path to the JSON file to be validated.
#
# Usage: validate_input "/path/to/your/json/file.json"
function validate_input() {
  [[ -z "${1}" ]] && print_error "Please provide tfvar.json file as 1st argument" && return 1 || local json_tfvars="${1}" ;

  # Check if the file exists
  if [[ ! -f "${json_tfvars}" ]]; then
    print_error "File '${json_tfvars}' does not exist."
    exit 1
  fi

  # Validate 'aws_k8s_regions'
  if ! jq -e '.aws_k8s_regions' "${json_tfvars}" > /dev/null; then
    print_error "Missing 'aws_k8s_regions' in the JSON."
    return 1
  fi

  # Validate 'azure_k8s_regions'
  if ! jq -e '.azure_k8s_regions' "${json_tfvars}" > /dev/null; then
    print_error "Missing 'azure_k8s_regions' in the JSON."
    return 1
  fi

  # Validate 'dns_provider'
  if ! jq -e '.dns_provider | select(. == "aws" or . == "gcp" or . == "azure")' "${json_tfvars}" > /dev/null; then
    print_error "Invalid 'dns_provider' value. It should be 'aws', 'gcp', or 'azure'."
    return 1
  fi

  # Validate 'gcp_k8s_regions'
  if ! jq -e '.gcp_k8s_regions' "${json_tfvars}" > /dev/null; then
    print_error "Missing 'gcp_k8s_regions' in the JSON."
    return 1
  fi

  # Validate 'name_prefix'
  if ! jq -e '.name_prefix' "${json_tfvars}" > /dev/null; then
    print_error "Missing 'name_prefix' in the JSON."
    return 1
  fi

  # Validate 'tetrate_owner'
  if ! jq -e '.tetrate_owner' "${json_tfvars}" > /dev/null; then
    print_error "Missing 'tetrate_owner' in the JSON."
    return 1
  fi

  # Validate 'tetrate_team'
  if ! jq -e '.tetrate_team' "${json_tfvars}" > /dev/null; then
    print_error "Missing 'tetrate_team' in the JSON."
    return 1
  fi

  # Validate 'tsb_fqdn'
  if ! jq -e '.tsb_fqdn' "${json_tfvars}" > /dev/null; then
    print_error "Missing 'tsb_fqdn' in the JSON."
    return 1
  fi

  # Validate 'tsb_image_sync_apikey'
  if ! jq -e '.tsb_image_sync_apikey' "${json_tfvars}" > /dev/null; then
    print_error "Missing 'tsb_image_sync_apikey' in the JSON."
    return 1
  fi

  # Validate 'tsb_image_sync_username'
  if ! jq -e '.tsb_image_sync_username' "${json_tfvars}" > /dev/null; then
    print_error "Missing 'tsb_image_sync_username' in the JSON."
    return 1
  fi

  # Validate 'tsb_mp' structure
  if ! jq -e '.tsb_mp | select(has("cloud") and has("cluster_id"))' "${json_tfvars}" > /dev/null; then
    print_error "Invalid structure in 'tsb_mp'. Ensure it has 'cloud' and 'cluster_id'."
    return 1
  fi

  # Validate 'tsb_org'
  if ! jq -e '.tsb_org' "${json_tfvars}" > /dev/null; then
    print_error "Missing 'tsb_org' in the JSON."
    return 1
  fi

  # Validate 'tsb_password'
  if ! jq -e '.tsb_password' "${json_tfvars}" > /dev/null; then
    print_error "Missing 'tsb_password' in the JSON."
    return 1
  fi

  # Validate 'tsb_version'
  if ! jq -e '.tsb_version' "${json_tfvars}" > /dev/null; then
    print_error "Missing 'tsb_version' in the JSON."
    return 1
  fi

  print_info "JSON structure of '${json_tfvars}' is valid."
}

#
# Main execution
#
case "${ACTION}" in
  help)
    help
    ;;
  validate_input)
    print_stage "Going to validate ${TFVARS_JSON} for correctness"
    validate_input "${TFVARS_JSON}"
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac