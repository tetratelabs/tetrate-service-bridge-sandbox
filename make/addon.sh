#!/usr/bin/env bash
#
# Helper script for addons: deploy and destroy of argocd, fluxcd, tsb-monitoring and external-dns.
BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR

# shellcheck source=/dev/null
source "${BASE_DIR}/helpers.sh"
# shellcheck source=/dev/null
source "${BASE_DIR}/variables.sh"

ACTION=${1}
CLOUD_PROVIDER=${2}
ADDON_NAME=${3}

# Validate input values.
SUPPORTED_ACTIONS=("deploy_infra" "destroy_infra" "refresh_token_k8s")
if ! [[ " ${SUPPORTED_ACTIONS[*]} " == *" ${ACTION} "* ]]; then
  print_error "Invalid action. Must be one of '${SUPPORTED_ACTIONS[*]}'."
  exit 1
fi
SUPPORTED_CLOUDS=("azure" "aws" "gcp")
if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${ACTION} "* ]]; then
  print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'."
  exit 1
fi
SUPPORTED_ADDONS=("argocd" "fluxcd" "tsb-monitoring" "external-dns")
if ! [[ " ${SUPPORTED_ADDONS[*]} " == *" ${ADDON_NAME} "* ]]; then
  print_error "Invalid addon name. Must be one of '${SUPPORTED_ADDONS[*]}'."
  exit 1
fi


# This function provides help information for the script.
function help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands:"
  echo "  help                                        Display this help message."
  echo "  deploy_addon  <cloud_provider> <addon_name> Deploy addon on the specified cloud provider."
  echo "  destroy_addon <cloud_provider> <addon_name> Destroy addon on the specified cloud provider."
}


# This function deploys the specified addon on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#   $2 - The addon name ("argocd", "fluxcd", "tsb-monitoring", or 'external-dns').
#
# Usage: deploy_addon "azure" "argocd"
function deploy_addon() {
  [[ -z "${1}" ]] && print_error "Please provide cloud provider as 1st argument" && return 1 || local cloud_provider="${1}" ;
  [[ -z "${2}" ]] && print_error "Please provide addon name as 2nd argument" && return 1 || local addon_name="${2}" ;

  # Deployment logic here
  print_info "Going to deploy addon '${addon_name}' on cloud '${cloud_provider}'"
}

# This function destroy the specified addon on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#   $2 - The addon name ("argocd", "fluxcd", "tsb-monitoring", or 'external-dns').
#
# Usage: destroy_addon "azure" "argocd"
function destroy_addon() {
  [[ -z "${1}" ]] && print_error "Please provide cloud provider as 1st argument" && return 1 || local cloud_provider="${1}" ;
  [[ -z "${2}" ]] && print_error "Please provide addon name as 2nd argument" && return 1 || local addon_name="${2}" ;

  # Destroy logic here
  print_info "Going to destroy addon '${addon_name}' on cloud '${cloud_provider}'"
}


#
# Main execution.
#
case "${ACTION}" in
  help)
    help
    ;;
  deploy_addon)
    print_stage "Going to deploy addon ${ADDON_NAME} on cloud ${CLOUD_PROVIDER}" 
    deploy_addon "${CLOUD_PROVIDER}" "${ADDON_NAME}"
    ;;
  destroy_addon)
    print_stage "Going to destroy addon ${ADDON_NAME} on cloud ${CLOUD_PROVIDER}"
    destroy_addon "${CLOUD_PROVIDER}" "${ADDON_NAME}"
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac
